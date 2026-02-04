module Ai
  class EmpathyMessageService
    RETRY_MAX = 2
    RETRY_BASE_SLEEP = 1.0

    # 会話履歴：最大何往復ぶん見るか（ユーザー/AI合わせて最大 24 件くらい）
    RECENT_TURNS = 12
    # 履歴が長すぎる時の保険（文字数）
    MAX_LOG_CHARS = 6_000

    def initialize(client: OpenAI::Client.new)
      @client = client
    end

    def generate_for(post:, user:, buddy: nil)
      buddy ||= user.buddy

      Ai::RateLimiter.new(user).check_and_count!(kind: :reply)

      requested_at = Time.current
      response     = nil

      begin
        recent_log = build_recent_log(post)

        response = with_retry_on_429 do
          @client.chat(
            parameters: {
              model: "gpt-4o-mini",
              messages: [
                { role: "system", content: system_prompt_for(user:, buddy:) },
                { role: "user", content: user_prompt(post, user: user, recent_log: recent_log) }
              ],
              temperature: 0.85
            }
          )
        end

        raw     = response.dig("choices", 0, "message", "content").to_s
        cleaned = raw.sub(/\A[　[:space:]]+/, "")

        ai_message = AiMessage.create!(
          user:    user,
          buddy:   buddy,
          post:    post,
          kind:    :reply,
          content: cleaned
        )

        log_success(
          user:         user,
          post:         post,
          ai_message:   ai_message,
          requested_at: requested_at,
          responded_at: Time.current,
          response:     response
        )

        cleaned
      rescue Ai::RateLimiter::LimitExceeded
        raise
      rescue Faraday::TooManyRequestsError => e
        fallback = fallback_message
        ai_message = AiMessage.create!(
          user:    user,
          buddy:   buddy,
          post:    post,
          kind:    :reply,
          content: fallback
        )

        log_error(
          user:         user,
          post:         post,
          requested_at: requested_at,
          responded_at: Time.current,
          response:     response,
          error:        e
        )

        fallback
      rescue => e
        fallback = fallback_message
        ai_message = AiMessage.create!(
          user:    user,
          buddy:   buddy,
          post:    post,
          kind:    :reply,
          content: fallback
        )

        log_error(
          user:         user,
          post:         post,
          requested_at: requested_at,
          responded_at: Time.current,
          response:     response,
          error:        e
        )

        fallback
      end
    end

    private

    # ---- 会話履歴を作る（BuddyMessage + AiMessage を時系列で混ぜる）----
    def build_recent_log(post)
      list = []

      if defined?(BuddyMessage)
        list += BuddyMessage.where(post: post).order(:created_at).to_a
      end

      # reply: 受容 / tip: 深掘りやまとめ（運用上tipに載ってる） / weekly: 自己PRまとめ
      list += AiMessage.where(post: post, kind: [:reply, :tip, :weekly]).order(:created_at).to_a

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

      # 長すぎる場合は末尾優先でカット（直近文脈が重要）
      if text.length > MAX_LOG_CHARS
        text = text[-MAX_LOG_CHARS..]
      end

      text
    end

    # 429 のときだけ短くリトライ（指数バックオフ）
    def with_retry_on_429
      attempts = 0

      begin
        yield
      rescue Faraday::TooManyRequestsError
        attempts += 1
        raise if attempts > RETRY_MAX

        sleep_time = RETRY_BASE_SLEEP * (2 ** (attempts - 1))
        sleep(sleep_time)
        retry
      end
    end

    def fallback_message
      "いまAIバディの返信が混み合っています…！少し時間をおいてから、もう一度開いてみてください🙏"
    end

    # ===== ログ関連 =====

    def log_success(user:, post:, ai_message:, requested_at:, responded_at:, response:)
      usage = extract_usage(response)

      AiLog.create!(
        user:        user,
        post:        post,
        ai_message:  ai_message,
        provider:    "openai",
        model:       "gpt-4o-mini",
        variant:     nil,
        prompt_tokens:     usage[:prompt_tokens],
        completion_tokens: usage[:completion_tokens],
        total_tokens:      usage[:total_tokens],
        latency_ms:  ((responded_at - requested_at) * 1000).round,
        status:      :success,
        requested_at: requested_at,
        responded_at: responded_at
      )
    rescue => log_error
      Rails.logger.error("[AiLog] failed to log success: #{log_error.class} #{log_error.message}")
    end

    def log_error(user:, post:, requested_at:, responded_at:, response:, error:)
      usage = extract_usage(response)

      AiLog.create!(
        user:        user,
        post:        post,
        provider:    "openai",
        model:       "gpt-4o-mini",
        variant:     nil,
        prompt_tokens:     usage[:prompt_tokens],
        completion_tokens: usage[:completion_tokens],
        total_tokens:      usage[:total_tokens],
        latency_ms:  ((responded_at - requested_at) * 1000).round,
        status:      :error,
        error_class:   error.class.name,
        error_message: error.message,
        requested_at:  requested_at,
        responded_at:  responded_at
      )
    rescue => log_error
      Rails.logger.error("[AiLog] failed to log error: #{log_error.class} #{log_error.message}")
    end

    def extract_usage(response)
      usage = response.is_a?(Hash) ? (response["usage"] || response[:usage]) : nil
      return { prompt_tokens: nil, completion_tokens: nil, total_tokens: nil } unless usage

      {
        prompt_tokens:     usage["prompt_tokens"]     || usage[:prompt_tokens],
        completion_tokens: usage["completion_tokens"] || usage[:completion_tokens],
        total_tokens:      usage["total_tokens"]      || usage[:total_tokens]
      }
    end

    # ===== プロンプト =====

    def system_prompt_for(user:, buddy:)
      type = prompt_type_for(user:, buddy:)
      prompt = Ai::PromptRepository.for(type, user_nickname: user.nickname)
      prompt[:system]
    end

    def prompt_type_for(user:, buddy:)
      return buddy.code if buddy&.respond_to?(:code) && buddy.code.present?

      if user.respond_to?(:profile) && user.profile&.social_type.present?
        return user.profile.social_type
      end

      :default
    end

    # ここが変更点：会話ログを渡して「流れを踏まえた受容」にする
    def user_prompt(post, user:, recent_log:)
      <<~PROMPT
        ユーザーのニックネームは「#{user.nickname.presence || "あなた"}」です。
        このニックネームを必ず最初の2文以内に1回使って呼びかけてください。
        投稿本文に出てくる他人の名前を、ユーザー名として呼ぶのは禁止です。

        あなたは「会話全体の流れ」を踏まえて返信してください。
        直前だけに反応せず、ユーザーが今どんな状態かを自然につなげて受け止めてください。
        ただし、ログにないことは断定しないでください。

        会話ログ（時系列）：
        #{recent_log}

        今回ユーザーが送った内容（最新）：
        ---
        #{post.body}
        ---
      PROMPT
    end
  end
end
