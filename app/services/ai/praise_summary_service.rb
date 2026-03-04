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

    # --- バディの“人格”をできるだけ拾って system に入れる ---
    def system_prompt(buddy:, user:)
      name = buddy&.display_name.presence || buddy&.name.presence || "AIバディ"

      tone =
        buddy&.try(:tone).presence ||
        buddy&.try(:speaking_style).presence ||
        buddy&.try(:voice).presence

      personality =
        buddy&.try(:personality).presence ||
        buddy&.try(:description).presence ||
        buddy&.try(:profile).presence ||
        buddy&.try(:concept).presence ||
        buddy&.try(:prompt).presence

      first_person =
        buddy&.try(:first_person).presence ||
        buddy&.try(:pronoun).presence

      ending =
        buddy&.try(:ending).presence ||
        buddy&.try(:phrase).presence ||
        buddy&.try(:speech_ending).presence

      persona_lines = []
      persona_lines << "話し方のトーン：#{tone}" if tone.present?
      persona_lines << "性格・スタンス：#{personality}" if personality.present?
      persona_lines << "一人称：#{first_person}" if first_person.present?
      persona_lines << "語尾・口癖：#{ending}" if ending.present?

      persona_block =
        if persona_lines.any?
          "【バディ設定】\n" + persona_lines.join("\n")
        else
          "【バディ設定】\nやさしく、否定せず、安心感のある相棒として話してください。"
        end

      # 関西弁の強制（レオ想定：名前で判定。speaking_style等に「関西」が入っててもOK）
      kansai = [ name, tone, personality, ending ].compact.join(" ").match?(/関西|大阪|レオ/)
      dialect_rule =
        if kansai
          <<~DIALECT
            方言ルール：
            - 必ず関西弁で話す（箇条書きも含めて関西弁）
            - 「〜している」「〜です/ます」調は極力使わない
            - やわらかい関西弁（きつい/煽り/ツッコミ過多は禁止）
          DIALECT
        else
          ""
        end

      <<~SYS
        あなたは「#{name}」として、ユーザーの会話内容をやさしく整理し、前向きな言葉で褒める相棒です。
        出力は日本語。自己PR・応募書類風の文体は禁止。

        #{persona_block}

        #{dialect_rule}

        目的：
        - ユーザーが「自分って悪くないかも」と感じられるように、事実ベースで優しく言語化する。

        重要ルール：
        - 会話ログに根拠がある範囲だけを書く（盛らない）
        - 説教しない / 断定しない / 責めない
        - 読みやすさ優先（長文にしない）
        - STAR/CAR/自己PR/面接などの単語は出さない
        - 見出しラベル（「まとめ」「いいところ」「次の一歩」等）は出さない

        出力フォーマット（順序を守る・番号は付けない）：
        - 最初に、2〜3行でやさしい要約を書く（箇条書き禁止）
        - 次に、「いいところ」を3つだけ箇条書きで書く
          - 形式は必ず「- 強み：根拠の具体文」
          - 強みは短い名詞（例：思いやり / 自己理解 / 継続力 / 表現力 / 誠実さ）
        - 次に、1行だけ「そういうところ素敵だね」と温かく添える（絵文字は0〜1個）
        - 最後に、負担のない「次の一歩」を1行だけ提案する（命令禁止）
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

      AiMessage.where(post: post, kind: %i[reply tip])
              .order(:created_at)
              .each do |m|
        parts << "【AI】#{m.content}"
      end

      parts.join("\n")
    end
  end
end
