module Ai
  class EmpathyMessageService
    def initialize(client: OpenAI::Client.new)
      @client = client
    end

    # 投稿 + ユーザー(+任意でバディ) を渡すと共感メッセージ(文字列)を返す
    def generate_for(post:, user:, buddy: nil)
      buddy ||= user.buddy

      # ここでレート制限
      Ai::RateLimiter.new(user).check_and_count!(kind: :reply)

      requested_at = Time.current
      response     = nil

      begin
        response = @client.chat(
          parameters: {
            model: "gpt-4o-mini",
            messages: [
              { role: "system", content: system_prompt_for(user:, buddy:) },
              { role: "user",   content: user_prompt(post) }
            ],
            temperature: 0.85
          }
        )

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
          user:        user,
          post:        post,
          ai_message:  ai_message,
          requested_at: requested_at,
          responded_at: Time.current,
          response:    response
        )

        cleaned
      rescue => e
        # APIから何か返っていれば usage も拾いたいので response はそのまま渡す
        log_error(
          user:        user,
          post:        post,
          requested_at: requested_at,
          responded_at: Time.current,
          response:    response,
          error:       e
        )
        raise e
      end
    end

    private

    # ===== ここからログ関連 =====

    def log_success(user:, post:, ai_message:, requested_at:, responded_at:, response:)
      usage = extract_usage(response)

      AiLog.create!(
        user:       user,
        post:       post,
        ai_message: ai_message,
        provider:   "openai",
        model:      "gpt-4o-mini",
        variant:    nil, # 後で A/B 導入したら "A"/"B" を入れる

        prompt_tokens:     usage[:prompt_tokens],
        completion_tokens: usage[:completion_tokens],
        total_tokens:      usage[:total_tokens],

        latency_ms: ((responded_at - requested_at) * 1000).round,
        status:     :success,
        requested_at: requested_at,
        responded_at: responded_at
      )
    rescue => log_error
      # ログ記録自体のエラーで本処理を落とさないようにする
      Rails.logger.error("[AiLog] failed to log success: #{log_error.class} #{log_error.message}")
    end

    def log_error(user:, post:, requested_at:, responded_at:, response:, error:)
      usage = extract_usage(response)

      AiLog.create!(
        user:       user,
        post:       post,
        provider:   "openai",
        model:      "gpt-4o-mini",
        variant:    nil,

        prompt_tokens:     usage[:prompt_tokens],
        completion_tokens: usage[:completion_tokens],
        total_tokens:      usage[:total_tokens],

        latency_ms: ((responded_at - requested_at) * 1000).round,
        status:      :error,
        error_class: error.class.name,
        error_message: error.message,
        requested_at:  requested_at,
        responded_at:  responded_at
      )
    rescue => log_error
      Rails.logger.error("[AiLog] failed to log error: #{log_error.class} #{log_error.message}")
    end

    # OpenAI の usage 情報を安全に取り出す
    def extract_usage(response)
      usage = response.is_a?(Hash) ? (response["usage"] || response[:usage]) : nil
      return { prompt_tokens: nil, completion_tokens: nil, total_tokens: nil } unless usage

      {
        prompt_tokens:     usage["prompt_tokens"]     || usage[:prompt_tokens],
        completion_tokens: usage["completion_tokens"] || usage[:completion_tokens],
        total_tokens:      usage["total_tokens"]      || usage[:total_tokens]
      }
    end

    # ===== ここから元のメソッド =====

    # ① ここで「どのタイプのプロンプトを使うか」を決める
    def system_prompt_for(user:, buddy:)
      type = prompt_type_for(user:, buddy:)
      prompt_config = Ai::PromptRepository.for(type)
      prompt_config[:system]
    end

    # ② social_type / buddy.code からタイプを決定
    def prompt_type_for(user:, buddy:)
      # 1. バディに code があればそれを優先（'analytical','amiable' など）
      return buddy.code if buddy&.respond_to?(:code) && buddy.code.present?

      # 2. プロフィールに social_type があればそれを
      if user.respond_to?(:profile) && user.profile&.social_type.present?
        return user.profile.social_type
      end

      # 3. どうしても無ければ :default
      :default
    end

    # ③ user_prompt(post) は今まで通りで OK
    def user_prompt(post)
      <<~PROMPT
        ユーザーの今日のつぶやきです。
        この内容にやさしく共感し、ねぎらいのメッセージを送ってください。

        ---
        #{post.body}
        ---
      PROMPT
    end
  end
end
