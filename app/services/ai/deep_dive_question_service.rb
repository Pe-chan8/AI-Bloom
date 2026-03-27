module Ai
  class DeepDiveQuestionService
    RETRY_MAX = 2
    RETRY_BASE_SLEEP = 1.0

    RECENT_TURNS = 6
    MAX_LOG_CHARS = 6_000

    def initialize(client: OpenAI::Client.new)
      @client = client
    end

    def generate_for(post:, user:, buddy: nil)
      buddy ||= user.buddy

      begin
        Ai::RateLimiter.new(user).check_and_count!(kind: :tip)
      rescue NameError, NoMethodError
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
                { role: "system", content: system_prompt_for(user: user, buddy: buddy) },
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

    def build_recent_log(post)
      list = []
      list += BuddyMessage.where(post: post).order(created_at: :asc).to_a if defined?(BuddyMessage)
      list += AiMessage.where(post: post, kind: %i[reply tip weekly])
                      .includes(:buddy)
                      .order(created_at: :asc)
                      .to_a
      list = list.sort_by(&:created_at)
      list = list.last(RECENT_TURNS * 2)

      text = list.map do |m|
        if defined?(BuddyMessage) && m.is_a?(BuddyMessage)
          "【ユーザー】#{m.content}"
        else
          kind = m.respond_to?(:kind) ? m.kind.to_s : ""
          label =
            case kind
            when "reply"  then "【AI(受容)】"
            when "tip"    then "【AI(深掘り/まとめ)】"
            when "weekly" then "【AI(強みまとめ)】"
            else "【AI】"
            end
          "#{label}#{m.content}"
        end
      end.join("\n")

      text = text[-MAX_LOG_CHARS..] if text.length > MAX_LOG_CHARS
      text
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

    # 性格(system) + 深掘り用途の追加指示
    def system_prompt_for(user:, buddy:)
      type = prompt_type_for(user: user, buddy: buddy)
      base = Ai::PromptRepository.system_for(
        type: type,
        user_nickname: user.nickname,
        buddy: buddy
      )[:system]

      base + "\n\n" + <<~SYS
        ▼追加指示（やさしい深掘り問いかけ）

        - あなたは「答えを引き出すAI」ではなく、
          ユーザーの隣に座って一緒に振り返る“やさしいバディ”です。

        - 目的：
          ユーザー自身が
          「自分、こんなこと大事にしてたんだ」
          「これ、意外と頑張ってたかも」
          と気づけるきっかけをつくること。

        - 質問は1〜2個まで。
          どちらも“短く・やわらかく・答えやすく”。

        - 直前の会話ログを必ず参考にし、
          「今の流れを受け止めた問いかけ」にしてください。

        - 1つ目：
          出来事や気持ちを、そのまま眺める問い
          （例：どんな場面だったか／そのときどんな気持ちだったか）

        - 2つ目：
          無理に前向きにしない“気づきの問い”
          （例：大事にしてたこと／自然にやっていた工夫／次も使えそうなこと）

        - 断定しない・評価しない・正解を決めない。
          「〜だったのかな」「よかったら」で問いかける。

        - 読んだときに
          「責められていない」「急かされていない」
          と感じる文だけを書いてください。
      SYS
    end

    def prompt_type_for(user:, buddy:)
      return buddy.code if buddy&.respond_to?(:code) && buddy.code.present?
      if user.respond_to?(:profile) && user.profile&.social_type.present?
        return user.profile.social_type
      end
      :default
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
        - 質問は短く、答えやすく。
      PROMPT
    end

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
