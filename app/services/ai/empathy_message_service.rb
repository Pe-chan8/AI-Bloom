module Ai
  class EmpathyMessageService
    # 429/一時エラー時のリトライ回数
    RETRY_MAX = 2
    # リトライ間隔（秒）※指数バックオフのベース
    RETRY_BASE_SLEEP = 1.0

    def initialize(client: OpenAI::Client.new)
      @client = client
    end

    # 投稿 + ユーザー(+任意でバディ) を渡すと共感メッセージ(文字列)を返す
    # 成功: AiMessage を作って content を返す
    # 失敗(429等): 例外は投げず、フォールバック文を保存して返す（画面が崩れない）
    def generate_for(post:, user:, buddy: nil)
      buddy ||= user.buddy

      # ここでレート制限（自前）
      Ai::RateLimiter.new(user).check_and_count!(kind: :reply)

      requested_at = Time.current
      response     = nil

      begin
        response = with_retry_on_429 do
          @client.chat(
            parameters: {
              model: "gpt-4o-mini",
              messages: [
                { role: "system", content: system_prompt_for(user:, buddy:) },
                { role: "user", content: user_prompt(post, user: user) }
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
        # 自前レート制限はそのまま上に投げる（show側で表示分岐してるため）
        raise
      rescue Faraday::TooManyRequestsError => e
        # OpenAI 429 は「画面が壊れない」方が大事なのでフォールバック保存して返す
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
        # その他のエラーもフォールバック保存して返す（必要なら raise に変えてもOK）
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

    def user_prompt(post, user:)
      <<~PROMPT
        ユーザーのニックネームは「#{user.nickname.presence || "あなた"}」です。
        このニックネームを必ず最初の2文以内に1回使って呼びかけてください。
        投稿本文に出てくる他人の名前を、ユーザー名として呼ぶのは禁止です。

        ユーザーの今日のつぶやきです。
        この内容にやさしく共感し、ねぎらいのメッセージを送ってください。

        ---
        #{post.body}
        ---
      PROMPT
    end
  end
end
