module Ai
  class PraiseSummaryService
    RETRY_MAX = 2
    RETRY_BASE_SLEEP = 1.0

    def initialize(client: OpenAI::Client.new)
      @client = client
    end

    # チャット内容を「まとめ/褒め/強み言い換え」で返す（AiMessage kind: :tip で保存）
    def generate_for(post:, user:, buddy: nil)
      buddy ||= user.buddy

      # 自前レート制限（praise_summary は tip 扱いでOK）
      begin
        Ai::RateLimiter.new(user).check_and_count!(kind: :tip)
      rescue NameError, NoMethodError
        # RateLimiterが無い/未実装でも落とさない
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
                { role: "system", content: system_prompt(buddy: buddy, user: user) },
                { role: "user", content: user_prompt(post: post, user: user, timeline: timeline) }
              ],
              temperature: 0.7
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

        cleaned
      rescue Faraday::TooManyRequestsError => e
        Rails.logger.warn("[PraiseSummaryService] 429 TooManyRequests: #{e.message}")
        fallback = fallback_message
        AiMessage.create!(user: user, buddy: buddy, post: post, kind: :tip, content: fallback)
        fallback
      rescue => e
        Rails.logger.error("[PraiseSummaryService] error: #{e.class} #{e.message}")
        fallback = fallback_message
        AiMessage.create!(user: user, buddy: buddy, post: post, kind: :tip, content: fallback)
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
      "いま「まとめ」の生成が混み合っています…！少し時間をおいてからもう一度押してみてね🙏"
    end

    def system_prompt(buddy:, user:)
      name = buddy&.display_name.presence || buddy&.name.presence || "AIバディ"
      <<~SYS
        あなたは「#{name}」として、ユーザーの会話内容をやさしく整理し、前向きな言葉で褒める相棒です。
        出力は日本語。自己PR・応募書類風の文体は禁止。

        目的：
        - ユーザーが「自分って悪くないかも」と感じられるように、事実ベースで優しく言語化する。

        重要ルール：
        - 会話ログに根拠がある範囲だけを書く（盛らない）
        - 説教しない / 断定しない / 責めない
        - 長文にしない（読みやすさ優先）
        - STAR/CAR/自己PR/面接などの単語は出さない
        - 「1)」「2)」などの番号、見出しの数字は一切使わない
        - 「まとめ」「いいところ」「次の一歩」などの見出しラベルも出さない

        出力フォーマット（この形を厳守）：
        1) 最初に、2〜3行でやさしい要約を書く（箇条書き禁止）
        2) 次に、ユーザーの「いいところ」を3つだけ箇条書きで書く
          - 形式は必ず「- 強み：具体的な根拠文章」
          - 強みは短い名詞（例：思いやり / 自己理解 / 継続力 / 表現力 / 誠実さ）
          - 根拠文章は会話ログの内容に結びつく具体文
        3) その次に、1行だけ「そういうところ素敵だね」と温かく添える（絵文字は0〜1個）
        4) 最後に、負担のない「次の一歩」を1行だけ提案する（命令禁止）
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

        指示：
        - 上のログだけを根拠に、「まとめ/いいところ/素敵だね/次の一歩」を出してください。
      PROMPT
    end

    def build_timeline_text(post)
      parts = []

      if defined?(BuddyMessage)
        BuddyMessage.where(post: post).order(:created_at).each do |m|
          parts << "【ユーザー】#{m.content}"
        end
      end

      AiMessage.where(post: post, kind: [ :reply, :tip ]).order(:created_at).each do |m|
        parts << "【AI】#{m.content}"
      end

      parts.join("\n")
    end
  end
end
