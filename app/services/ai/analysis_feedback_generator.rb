module Ai
  class AnalysisFeedbackGenerator
    Result = Struct.new(:success?, :error, keyword_init: true)

    RECENT_POSTS_LIMIT = 8

    SYSTEM_PROMPT = <<~TEXT.strip
      あなたは『AI-Bloom』のバディです。
      やさしく、断定しすぎず、短めに寄り添ってください。
      出力はユーザーに見せるための「分析カード用JSON」です。
    TEXT

    def initialize(user)
      @user = user
    end

    def call(category:, subcategory:)
      category    = category.presence || "all"
      subcategory = subcategory.presence

      user_prompt = build_prompt(category: category, subcategory: subcategory)

      raw = Openai::Client.new.chat(
        system_prompt: SYSTEM_PROMPT,
        user_prompt: user_prompt
      )

      json_text = extract_json(raw)
      payload   = safe_parse_json(json_text)

      payload["meta"] ||= {}
      payload["meta"]["category"]    = category
      payload["meta"]["subcategory"] = subcategory

      AiMessage.create!(
        user: @user,
        kind: :analysis_feedback,
        category: category.to_s,
        subcategory: subcategory,
        content: payload.to_json
      )

      Result.new(success?: true)
    rescue => e
      Rails.logger.error("[Ai::AnalysisFeedbackGenerator] #{e.class}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
      Result.new(success?: false, error: e.message)
    end

    private

    def build_prompt(category:, subcategory:)
      template_path =
        if category.to_s == "all"
          Rails.root.join("app/ai/prompts/analysis/feedback_all.md")
        else
          Rails.root.join("app/ai/prompts/analysis/feedback.md")
        end

      template = template_path.exist? ? template_path.read : default_template
      stats    = build_stats(category: category, subcategory: subcategory)

      template
        .gsub("{{CATEGORY}}", category.to_s)
        .gsub("{{SUBCATEGORY}}", subcategory.to_s)
        .gsub("{{STATS_JSON}}", stats.to_json)
    end

    # 投稿本文を渡す（14日 + 最近の投稿）
    def build_stats(category:, subcategory:)
      end_date   = Time.zone.today
      start_date = end_date - 13.days

      base_scope = @user.posts.where(posted_at: start_date.beginning_of_day..end_date.end_of_day)

      scope = base_scope
      scope = scope.where(category: category) if category.present? && category != "all"
      scope = scope.where(subcategory: subcategory) if subcategory.present?

      moods = scope.where.not(mood: nil).pluck(:mood)
      mood_scores = moods.map { |m| ::MoodScale.score(m) }.compact
      mood_avg = mood_scores.any? ? (mood_scores.sum.to_f / mood_scores.size).round(2) : nil

      recent = scope.order(posted_at: :desc).limit(RECENT_POSTS_LIMIT).map do |p|
        {
          posted_at: p.posted_at&.to_date&.to_s,
          mood: p.mood,
          text: compact_text(p)
        }
      end

      stats = {
        meta: {
          today: Time.zone.today.to_s,
          range: { from: start_date.to_s, to: end_date.to_s },
          category: category,
          subcategory: subcategory
        },
        aggregate: {
          posts_count_14d: scope.count,
          mood_avg_14d: mood_avg
        },
        recent_posts: recent
      }

      if category.to_s == "all"
        stats[:category_top5] =
          base_scope.where.not(category: [ nil, "" ])
                    .group(:category)
                    .order(Arel.sql("COUNT(*) DESC"))
                    .limit(5)
                    .count
      end

      stats
    end

    def compact_text(post)
      candidates = [
        (post.respond_to?(:body) ? post.body : nil),
        (post.respond_to?(:content) ? post.content : nil),
        (post.respond_to?(:text) ? post.text : nil),
        (post.respond_to?(:note) ? post.note : nil)
      ].compact

      text = candidates.first.to_s
      text = text.gsub(/\s+/, " ").strip
      text = text[0, 240]
      text
    end

    def extract_json(text)
      s = text.to_s.strip
      s = s.gsub(/\A```(?:json)?\s*/i, "").gsub(/\s*```\z/, "").strip

      m = s.match(/\{.*\}/m)
      raise "JSON not found in AI response" unless m

      m[0]
    end

    def safe_parse_json(json_text)
      JSON.parse(json_text)
    rescue JSON::ParserError
      {
        "meta" => {},
        "strength_title" => "あなたらしさ",
        "strength_desc" => nil,
        "strength_items" => [],
        "weakness_title" => "無理が溜まりやすいところ",
        "weakness_desc" => nil,
        "weakness_items" => [],
        "tips_strength_title" => "あなたの良さをそっと活かすヒント",
        "tips_strength" => [],
        "tips_weakness_title" => "しんどいときのヒント",
        "tips_weakness" => []
      }
    end

    def default_template
      <<~MD
        # 出力ルール（最重要）
        - 出力は **JSONのみ**（前置き/説明/コードフェンス禁止）
        - 文章添削は禁止。ユーザーの「性格/考え方/行動の傾向」に着目
        - カテゴリ({{CATEGORY}})の文脈に合わせて言葉を変える
        - 「あなたらしさ」は最大3件。弱みは1〜3件でOK（無理に増やさない）
        - 「根拠/evidence」欄は出力しない

        # 入力情報（統計＋最近の投稿）
        カテゴリ: {{CATEGORY}}
        サブカテゴリ: {{SUBCATEGORY}}
        データ: {{STATS_JSON}}

        # 出力JSONスキーマ
        {
          "meta": { "category": "{{CATEGORY}}", "subcategory": "{{SUBCATEGORY}}" },

          "strength_title": "（カテゴリに合わせた見出し）",
          "strength_desc": "（短い説明。なければ null）",
          "strength_items": [
            {"label": "（傾向）", "short": "（やさしい一言）"}
          ],

          "weakness_title": "（カテゴリに合わせた見出し）",
          "weakness_desc": "（短い説明。なければ null）",
          "weakness_items": [
            {"label": "（つまずきやすい癖）", "short": "（やさしい一言）"}
          ],

          "tips_strength_title": "（カテゴリに合わせたヒント見出し）",
          "tips_strength": ["（箇条書き短文）"],

          "tips_weakness_title": "（カテゴリに合わせた支え方見出し）",
          "tips_weakness": ["（箇条書き短文）"]
        }
      MD
    end
  end
end
