class MoodTrendAnalyzer
  Point = Struct.new(:date, :avg, :count, keyword_init: true)

  def initialize(user)
    @user = user
  end

  def daily_points(days: 14, category: nil, subcategory: nil)
    end_date   = Time.zone.today
    start_date = end_date - (days - 1).days

    buckets = (0...days).map do |i|
      d = (start_date + i.days).to_date
      [ d, { posts: 0, scores: [] } ]
    end.to_h

    scope = @user.posts.where(posted_at: start_date.beginning_of_day..end_date.end_of_day)
    scope = scope.where(category: category) if category.present? && category != "all"
    scope = scope.where(subcategory: subcategory) if subcategory.present?

    scope.find_each do |post|
      d = post.posted_at&.to_date
      next if d.nil?
      next unless buckets.key?(d)

      buckets[d][:posts] += 1

      next if post.mood.nil?
      score = MoodScale.score(post.mood)
      next if score.nil?

      buckets[d][:scores] << score
    end

    buckets.map do |d, h|
      scores = h[:scores]
      avg = scores.any? ? (scores.sum.to_f / scores.size) : nil
      Point.new(date: d, avg: avg, count: h[:posts]) # ← 投稿数は全投稿
    end
  end
end
