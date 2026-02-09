class WeeklyOneLineSummary
  def initialize(user)
    @user = user
  end

  def call(category: "all")
    end_date   = Time.zone.today.end_of_week(:monday)
    start_date = end_date.beginning_of_week(:monday)

    posts = @user.posts.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
    posts = posts.where(category: category) unless category == "all"

    count = posts.count
    moods = posts.where.not(mood: nil).pluck(:mood).map(&:to_i)
    avg = moods.any? ? (moods.sum.to_f / moods.size) : nil

    top_sub = posts.where.not(subcategory: [ nil, "" ])
                   .group(:subcategory)
                   .order(Arel.sql("COUNT(*) DESC"))
                   .limit(1)
                   .count
                   .keys
                   .first

    parts = []
    parts << "今週は#{count}件"
    parts << (avg ? "気分は平均#{avg.round(1)}" : "気分は未記録が多め")
    parts << (top_sub ? "話題は「#{top_sub}」が多め" : nil)

    "（#{category_label(category)}）" + parts.compact.join(" / ")
  end

  private

  def category_label(key)
    {
      "all" => "全カテゴリー", "work" => "仕事", "love" => "恋愛",
      "family" => "家庭", "study" => "学習", "other" => "その他"
    }[key] || "全カテゴリー"
  end
end
