class MoodTrendAnalyzer
  Point = Struct.new(:date, :avg, :count, keyword_init: true)

  def initialize(user)
    @user = user
  end

  # days: 14 なら「今日含めて直近14日」
  def daily_points(days: 14, category: "all", subcategory: nil)
    end_date   = Time.zone.today
    start_date = end_date - (days - 1).days

    buckets = (0...days).map do |i|
      d = (start_date + i.days).to_date
      [ d, [] ]
    end.to_h

    posts = @user.posts
      .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
      .where.not(mood: nil)

    posts = posts.where(category: category) unless category == "all"
    posts = posts.where(subcategory: subcategory) if subcategory.present?

    posts.find_each do |post|
      d = post.created_at.to_date
      next unless buckets.key?(d)
      buckets[d] << mood_score(post.mood)
    end

    buckets.map do |d, scores|
      avg = scores.any? ? (scores.sum.to_f / scores.size) : nil
      Point.new(date: d, avg: avg, count: scores.size)
    end
  end

  private

  # moodが数値(1..5)想定。
  def mood_score(mood_value)
    mood_value.to_i
  end
end
