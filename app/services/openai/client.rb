require "openai"

module Openai
  class Client
    # NOTE: 将来モデルを差し替えやすいように定数化
    DEFAULT_MODEL = "gpt-4.1-mini" # 軽め＆安めのモデルを想定

    def initialize(model: DEFAULT_MODEL)
      @model = model
      @client = OpenAI::Client.new(
        access_token: ENV.fetch("OPENAI_API_KEY")
      )
    end

    # シンプルに「システム＋ユーザーの文章 → 1 メッセージ返す」ユーティリティ
    def chat(system_prompt:, user_prompt:)
      response = @client.chat(
        parameters: {
          model: @model,
          messages: [
            { role: "system", content: system_prompt },
            { role: "user",   content: user_prompt }
          ]
        }
      )

      # 例外やレスポンス構造の揺れに備えてガード
      response.dig("choices", 0, "message", "content") ||
        raise("OpenAI response format unexpected: #{response.inspect}")
    end
  end
end
