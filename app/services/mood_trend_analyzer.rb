class MoodTrendAnalyzer
  Point = Struct.new(:date, :avg, :count, keyword_init: true)

  def initialize(user)
    @user = user
  end

  # days: 14 なら「今日含めて14日」
  # category: "work" など / nil or "all" は絞り込みなし
  # subcategory: nil は絞り込みなし
  def daily_points(days: 14, category: nil, subcategory: nil)
    end_date   = Time.zone.today
    start_date = end_date - (days - 1).days

    buckets = (0...days).map do |i|
      d = (start_date + i.days).to_date
      [ d, [] ]
    end.to_h

    scope = @user.posts
                .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
                .where.not(mood: nil)

    scope = scope.where(category: category) if category.present? && category != "all"
    scope = scope.where(subcategory: subcategory) if subcategory.present?

    scope.find_each do |post|
      d = post.created_at.to_date
      next unless buckets.key?(d)

      score = MoodScale.score(post.mood)
      next if score.nil?

      buckets[d] << score
    end

    buckets.map do |d, scores|
      avg = scores.any? ? (scores.sum.to_f / scores.size) : nil
      Point.new(date: d, avg: avg, count: scores.size)
    end
  end
end
