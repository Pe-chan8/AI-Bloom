class WeeklyOneLineSummary
  def initialize(user)
    @user = user
  end

  # 戻り値：画面用に hash で返す（直近2週間：合計＋今週＋先週）
  def call(category: "all", subcategory: nil)
    category    = category.presence || "all"
    subcategory = subcategory.presence

    this_w = week_range(offset_weeks: 0)
    last_w = week_range(offset_weeks: 1)

    this_posts = posts_in_range(this_w[:from], this_w[:to], category: category, subcategory: subcategory)
    last_posts = posts_in_range(last_w[:from], last_w[:to], category: category, subcategory: subcategory)

    {
      category_label: category_label(category),
      total: {
        posts_count: this_posts.count + last_posts.count
      },
      this_week: summarize(this_posts),
      last_week: summarize(last_posts)
    }
  end

  private

  # offset_weeks: 0=今週, 1=先週
  def week_range(offset_weeks:)
    base = Time.zone.today - (7.days * offset_weeks)
    end_date   = base.end_of_week(:monday)
    start_date = end_date.beginning_of_week(:monday)
    { from: start_date.beginning_of_day, to: end_date.end_of_day }
  end

  def posts_in_range(from_time, to_time, category:, subcategory:)
    scope = @user.posts.where(posted_at: from_time..to_time)
    scope = scope.where(category: category) if category.present? && category != "all"
    scope = scope.where(subcategory: subcategory) if subcategory.present?
    scope
  end

  def summarize(posts)
    moods = posts.where.not(mood: nil).pluck(:mood)
    scores = moods.map { |m| ::MoodScale.score(m) }.compact
    avg = scores.any? ? (scores.sum.to_f / scores.size).round(1) : nil

    # 「多い言葉」：まずは subcategory の最多（軽量）
    top_word =
      posts.where.not(subcategory: [nil, ""])
           .group(:subcategory)
           .order(Arel.sql("COUNT(*) DESC"))
           .limit(1)
           .count
           .keys
           .first

    {
      posts_count: posts.count,
      mood_avg: avg,
      top_word: top_word
    }
  end

  def category_label(key)
    {
      "all" => "総合",
      "work" => "仕事",
      "love" => "恋愛",
      "family" => "家庭",
      "study" => "学習",
      "other" => "その他"
    }[key.to_s] || "総合"
  end
end
