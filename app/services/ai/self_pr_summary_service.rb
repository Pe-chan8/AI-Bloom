module Ai
  class SelfPrSummaryService
    RETRY_MAX = 2
    RETRY_BASE_SLEEP = 1.0

    def initialize(client: OpenAI::Client.new)
      @client = client
    end

    # 会話ログをもとに自己PRを生成して AiMessage(kind: :weekly) で保存して返す
    def generate_for(post:, user:, buddy: nil)
      buddy ||= user.buddy

      begin
        Ai::RateLimiter.new(user).check_and_count!(kind: :weekly)
      rescue NameError, NoMethodError
      end

      requested_at = Time.current
      response = nil

      begin
        timeline = build_timeline_text(post)

        response = with_retry_on_429 do
          @client.chat(
            parameters: {
              model: "gpt-4o-mini",
              messages: [
                { role: "system", content: system_prompt(user: user, buddy: buddy) },
                { role: "user", content: user_prompt(post: post, user: user, timeline: timeline) }
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
          kind: :weekly,
          content: cleaned
        )

        log_success(user: user, post: post, requested_at: requested_at, responded_at: Time.current, response: response)
        cleaned
      rescue Faraday::TooManyRequestsError => e
        fallback = fallback_message
        AiMessage.create!(user: user, buddy: buddy, post: post, kind: :weekly, content: fallback)
        log_error(user: user, post: post, requested_at: requested_at, responded_at: Time.current, response: response, error: e)
        fallback
      rescue => e
        fallback = fallback_message
        AiMessage.create!(user: user, buddy: buddy, post: post, kind: :weekly, content: fallback)
        log_error(user: user, post: post, requested_at: requested_at, responded_at: Time.current, response: response, error: e)
        fallback
      end
    end

    private

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
      "いま強みまとめの生成が混み合っています…！少し時間をおいてから、もう一度押してみてね🙏"
    end

    def system_prompt(user:, buddy:)
      name = buddy&.name.presence || "AIバディ"
      <<~SYS
        あなたは「#{name}」として、ユーザーの会話ログから「強みまとめ（自己PRの芯）」を作成するキャリア支援者です。
        出力は日本語。

        形式：
        1) 深掘り/まとめ（200〜350字）
        2) 箇条書き（短く）
           - 根拠エピソード要約：
           - 再現性（行動特性）：
           - 次の一言（面接の締め）：

        制約：
        - 盛りすぎない（ログに無いことを断定しない）
        - ユーザーの言葉/感情を尊重する
        - 読みやすく、やさしい口調
      SYS
    end

    def user_prompt(post:, user:, timeline:)
      <<~PROMPT
        ユーザー情報：
        - ニックネーム：#{user.nickname.presence || "あなた"}

        テーマ（タイトル）：
        #{post.title}

        会話ログ（時系列）：
        #{timeline}

        上記だけを根拠に「強みまとめ」を作ってください。
      PROMPT
    end

    def build_timeline_text(post)
      parts = []

      if defined?(BuddyMessage)
        BuddyMessage.where(post: post).order(:created_at).each do |m|
          parts << "【ユーザー】#{m.content}"
        end
      end

      AiMessage.where(post: post).order(:created_at).each do |m|
        kind = m.respond_to?(:kind) ? m.kind.to_s : ""
        label =
          case kind
          when "reply"  then "【AI(受容)】"
          when "tip"    then "【AI(深掘り)】"
          when "weekly" then "【AI(まとめ)】"
          else "【AI】"
          end
        parts << "#{label}#{m.content}"
      end

      parts.join("\n")
    end

    def log_success(user:, post:, requested_at:, responded_at:, response:)
      return unless defined?(AiLog)
      usage = extract_usage(response)

      AiLog.create!(
        user: user,
        post: post,
        provider: "openai",
        model: "gpt-4o-mini",
        variant: "self_pr",
        prompt_tokens: usage[:prompt_tokens],
        completion_tokens: usage[:completion_tokens],
        total_tokens: usage[:total_tokens],
        latency_ms: ((responded_at - requested_at) * 1000).round,
        status: :success,
        requested_at: requested_at,
        responded_at: responded_at
      )
    rescue => e
      Rails.logger.error("[AiLog] self_pr success log failed: #{e.class} #{e.message}")
    end

    def log_error(user:, post:, requested_at:, responded_at:, response:, error:)
      return unless defined?(AiLog)
      usage = extract_usage(response)

      AiLog.create!(
        user: user,
        post: post,
        provider: "openai",
        model: "gpt-4o-mini",
        variant: "self_pr",
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
      Rails.logger.error("[AiLog] self_pr error log failed: #{e.class} #{e.message}")
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
