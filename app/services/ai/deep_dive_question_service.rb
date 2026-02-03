module Ai
  class DeepDiveQuestionService
    RETRY_MAX = 2
    RETRY_BASE_SLEEP = 1.0

    # 直近ログを何往復ぶん見るか（ユーザー/AI合計で最大12件くらい）
    RECENT_TURNS = 6

    def initialize(client: OpenAI::Client.new)
      @client = client
    end

    # 深掘り質問（1〜2問）を生成して AiMessage(kind: :tip) に保存して返す
    def generate_for(post:, user:, buddy: nil)
      buddy ||= user.buddy

      begin
        Ai::RateLimiter.new(user).check_and_count!(kind: :tip)
      rescue NameError, NoMethodError
        # RateLimiterが無い/未実装でも落とさない
      end

      requested_at = Time.current
      response = nil

      begin
        recent_log = build_recent_log(post)

        response = with_retry_on_429 do
          @client.chat(
            parameters: {
              model: "gpt-4o-mini",
              messages: [
                { role: "system", content: system_prompt(user: user, buddy: buddy) },
                { role: "user", content: user_prompt(post: post, user: user, recent_log: recent_log) }
              ],
              temperature: 0.6
            }
          )
        end

        raw = response.dig("choices", 0, "message", "content").to_s
        cleaned = raw.sub(/\A[　[:space:]]+/, "")

        AiMessage.create!(
          user: user,
          buddy: buddy,
          post: post,
          kind: :tip,
          content: cleaned
        )

        log_success(user: user, post: post, requested_at: requested_at, responded_at: Time.current, response: response)
        cleaned
      rescue Faraday::TooManyRequestsError => e
        fallback = fallback_message
        AiMessage.create!(user: user, buddy: buddy, post: post, kind: :tip, content: fallback)
        log_error(user: user, post: post, requested_at: requested_at, responded_at: Time.current, response: response, error: e)
        fallback
      rescue => e
        fallback = fallback_message
        AiMessage.create!(user: user, buddy: buddy, post: post, kind: :tip, content: fallback)
        log_error(user: user, post: post, requested_at: requested_at, responded_at: Time.current, response: response, error: e)
        fallback
      end
    end

    private

    # ---- 直近ログ：BuddyMessage(ユーザー) + AiMessage(reply/tip/weekly) を時系列に混ぜる ----
    def build_recent_log(post)
      list = []

      if defined?(BuddyMessage)
        list += BuddyMessage.where(post: post).order(:created_at).to_a
      end

      list += AiMessage.where(post: post, kind: [:reply, :tip, :weekly]).order(:created_at).to_a
      list = list.sort_by(&:created_at)

      sliced = list.last(RECENT_TURNS * 2)

      sliced.map do |m|
        if defined?(BuddyMessage) && m.is_a?(BuddyMessage)
          "【ユーザー】#{m.content}"
        else
          kind = m.respond_to?(:kind) ? m.kind.to_s : ""
          label =
            case kind
            when "reply"  then "【AI(受容)】"
            when "tip"    then "【AI(深掘り)】"
            when "weekly" then "【AI(まとめ)】"
            else "【AI】"
            end
          "#{label}#{m.content}"
        end
      end.join("\n")
    end

    def with_retry_on_429
      attempts = 0
      begin
        yield
      rescue Faraday::TooManyRequestsError
        attempts += 1
        raise if attempts > RETRY_MAX
        sleep(RETRY_BASE_SLEEP * (2 ** (attempts - 1)))
        retry
      end
    end

    def fallback_message
      "いま深掘り質問の生成が混み合っています…！少し時間をおいてからもう一度押してみてね🙏"
    end

    def system_prompt(user:, buddy:)
      name = buddy&.name.presence || "AIバディ"
      <<~SYS
        あなたは「#{name}」として、ユーザーの振り返りをやさしく深掘りする相棒です。
        目的：ユーザーの経験から「強み・工夫・価値観・再現性」を引き出す。

        出力ルール：
        - 質問は1〜2個
        - できるだけ「直前ログの内容」を引用/参照して具体的に聞く
        - 1つ目は状況の具体化（何が起きた/何をした/どう感じた）
        - 2つ目は強み・工夫・再現性（なぜできた/どう工夫した/次も使える形）
        - 断定しない、責めない、短く、答えやすく
      SYS
    end

    def user_prompt(post:, user:, recent_log:)
      <<~PROMPT
        ユーザーのニックネーム：#{user.nickname.presence || "あなた"}

        テーマ（タイトル）：
        #{post.title}

        初回本文：
        #{post.body}

        直前の会話ログ（重要。ここを見て質問を具体化して）：
        #{recent_log}

        指示：
        - 上記ログを参照して「今の流れに合う」深掘り質問を1〜2個だけ出してください。
        - 回答しやすいように、質問は短く。
      PROMPT
    end

    # ---- ログ（AiLogがある場合のみ）----
    def log_success(user:, post:, requested_at:, responded_at:, response:)
      return unless defined?(AiLog)
      usage = extract_usage(response)

      AiLog.create!(
        user: user,
        post: post,
        provider: "openai",
        model: "gpt-4o-mini",
        variant: "deep_dive",
        prompt_tokens: usage[:prompt_tokens],
        completion_tokens: usage[:completion_tokens],
        total_tokens: usage[:total_tokens],
        latency_ms: ((responded_at - requested_at) * 1000).round,
        status: :success,
        requested_at: requested_at,
        responded_at: responded_at
      )
    rescue => e
      Rails.logger.error("[AiLog] deep_dive success log failed: #{e.class} #{e.message}")
    end

    def log_error(user:, post:, requested_at:, responded_at:, response:, error:)
      return unless defined?(AiLog)
      usage = extract_usage(response)

      AiLog.create!(
        user: user,
        post: post,
        provider: "openai",
        model: "gpt-4o-mini",
        variant: "deep_dive",
        prompt_tokens: usage[:prompt_tokens],
        completion_tokens: usage[:completion_tokens],
        total_tokens: usage[:total_tokens],
        latency_ms: ((responded_at - requested_at) * 1000).round,
        status: :error,
        error_class: error.class.name,
        error_message: error.message,
        requested_at: requested_at,
        responded_at: responded_at
      )
    rescue => e
      Rails.logger.error("[AiLog] deep_dive error log failed: #{e.class} #{e.message}")
    end

    def extract_usage(response)
      usage = response.is_a?(Hash) ? (response["usage"] || response[:usage]) : nil
      return { prompt_tokens: nil, completion_tokens: nil, total_tokens: nil } unless usage

      {
        prompt_tokens: usage["prompt_tokens"] || usage[:prompt_tokens],
        completion_tokens: usage["completion_tokens"] || usage[:completion_tokens],
        total_tokens: usage["total_tokens"] || usage[:total_tokens]
      }
    end
  end
end
