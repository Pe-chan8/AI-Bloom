class StrengthAnalyzer
  Point = Struct.new(:date, :avg, :count, keyword_init: true)

  def initialize(user)
    @user = user
  end

  def call
    {}
  end

  # とりあえず mood_trend と同じ形で日次ポイントを返す（必要なら）
  def daily_points(days: 14, category: "all", subcategory: nil)
    end_date   = Time.zone.today
    start_date = end_date - (days - 1).days

    buckets = (0...days).map { |i| [ (start_date + i.days).to_date, [] ] }.to_h

    scope = @user.posts
                 .where(posted_at: start_date.beginning_of_day..end_date.end_of_day)
                 .where.not(mood: nil)

    scope = scope.where(category: category) if category.present? && category != "all"
    scope = scope.where(subcategory: subcategory) if subcategory.present?

    scope.find_each do |post|
      d = post.posted_at.to_date
      next unless buckets.key?(d)

      buckets[d] << mood_score(post.mood)
    end

    buckets.map do |d, scores|
      avg = scores.any? ? (scores.sum.to_f / scores.size) : nil
      Point.new(date: d, avg: avg, count: scores.size)
    end
  end

  private

  # Post.mood enum 0..4想定 → 1..5へ
  def mood_score(mood)
    MoodTrendAnalyzer::MoodScale.score(mood)
  rescue NameError
    mood.to_i
  end
end
