module Ai
  class EmpathyMessageService
    # 将来テストしやすいように client は DI できるようにしておく
    def initialize(client: OpenAI::Client.new)
      @client = client
    end

    # 投稿 + ユーザー(+任意でバディ) を渡すと共感メッセージ(文字列)を返す
    def generate_for(post:, user:, buddy: nil)
    buddy ||= user.buddy
    response = @client.chat(
        parameters: {
        model: "gpt-4o-mini",
        messages: [
            { role: "system", content: system_prompt(user, buddy) },
            { role: "user",   content: user_prompt(post) }
        ],
        temperature: 0.85
        }
    )

    raw = response.dig("choices", 0, "message", "content").to_s

    cleaned = raw.lines.map { |line| line.gsub(/\A[ \t　\u00A0]+/, "") }.join

    cleaned.strip
    rescue => e
    Rails.logger.error "[Ai::EmpathyMessageService] #{e.class}: #{e.message}"
    nil
    end

    private

    # バディの性格・トーンをプロンプトに反映
    def system_prompt(user, buddy)
      buddy_name     = buddy&.name        || "AIバディ"
      tone_hint      = buddy&.tone_hint   || "やさしく、あたたかく、寄り添う雰囲気で話してください。"
      personality    = buddy&.respond_to?(:personality) ? buddy.personality : nil

      <<~PROMPT
        あなたはユーザーをそっと励ますペンギンのAIバディ「#{buddy_name}」です。

        ▼あなたのキャラクター
        - 話し方のトーン: #{tone_hint}
        #{ "- 性格: #{personality}" if personality.present? }

        ▼返信ルール
        - 返信は必ず日本語で、文頭に空白や改行を入れずに書き始めてください。
        - 文章量は 300 文字前後を目安にしてください（長くなりすぎないように）。
        - まずユーザーの気持ちをそのまま受け止めて言葉にしてください（受容）。
        - 次に、その等身大の頑張りや感情、成果をやさしく褒めて前向きな内容にしてください。
        - 最後に、「小さな一歩」をそっと応援するメッセージを添えてください。
        - 説教や押し付けはせず、「よく頑張っているね」というスタンスで話してください。
        - 同じ内容の投稿に対しても、毎回少し言い回しや例えを変えてください（完全なコピペはしない）。

        絵文字は 0〜2 個までの控えめな使用にしてください。
      PROMPT
    end

    def user_prompt(post)
      <<~PROMPT
        以下はユーザーが今日投稿したメモ（日記）です。

        ----
        #{post.body}
        ----

        この内容を読んだうえで、上記のルールに従ってメッセージを1つ作成してください。
      PROMPT
    end
  end
end
