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

    raw = response.dig("choices", 0, "message", "content").to_s
    cleaned = raw.sub(/\A[　[:space:]]+/, "")

    AiMessage.create!(
        user:    user,
        buddy:   buddy,
        post:    post,
        kind:    :reply,
        content: cleaned
    )

    cleaned
    end

    private

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

    # ③ user_prompt(post) は今まで通りで OK（必要なら整理）
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
