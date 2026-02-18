# frozen_string_literal: true

module Ai
  class EmpathyMessageService
    RETRY_MAX = 2
    RETRY_BASE_SLEEP = 1.0

    # 会話履歴：最大何往復ぶん見るか（ユーザー/AI合わせて最大 24 件くらい）
    RECENT_TURNS = 12
    # 履歴が長すぎる時の保険（文字数）
    MAX_LOG_CHARS = 6_000

    MODEL = "gpt-4o-mini"
    TEMPERATURE = 0.85

    def initialize(client: OpenAI::Client.new)
      @client = client
    end

    def generate_for(post:, user:, buddy: nil)
      buddy ||= user.buddy

      Ai::RateLimiter.new(user).check_and_count!(kind: :reply)

      requested_at = Time.current
      response     = nil

      begin
        recent_log = build_recent_log(post, buddy: buddy)

        messages = Ai::PromptBuilder.build_buddy_reply(
          user: user,
          buddy: buddy,
          post: post,
          recent_log: recent_log
        )

        response = with_retry_on_429 do
          @client.chat(
            parameters: {
              model: MODEL,
              messages: messages,
              temperature: TEMPERATURE
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
    # NOTE:
    # 口調混入を防ぐため、AiMessage は「今のbuddy」に紐づくものだけを採用する。
    def build_recent_log(post, buddy:)
      list = []

      if defined?(BuddyMessage)
        list += BuddyMessage.where(post: post).order(:created_at).to_a
      end

      # reply: 受容 / tip: 深掘りやまとめ / weekly: 強みまとめ
      ai_scope = AiMessage.where(post: post, kind: [ :reply, :tip, :weekly ])
      ai_scope = ai_scope.where(buddy: buddy) if buddy.present?
      list += ai_scope.order(:created_at).to_a

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
        model:       MODEL,
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
        model:       MODEL,
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
  end
end
