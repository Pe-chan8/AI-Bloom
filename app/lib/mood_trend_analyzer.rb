class MoodTrendAnalyzer
  Point = Struct.new(:date, :avg, :count, keyword_init: true)

  def initialize(user)
    @user = user
  end

  class MoodScale
    # Post.mood enum: very_negative..very_positive が 0..4 の想定
    MAP = {
      "very_negative" => 0,
      "negative"      => 1,
      "neutral"       => 2,
      "positive"      => 3,
      "very_positive" => 4
    }.freeze

    def self.score(mood)
      raw = MAP[mood.to_s]
      return nil if raw.nil?
      raw + 1 # 1..5 にする
    end
  end

  # 投稿がない日は avg=nil（点なし）
  def daily_points(days: 14, category: "all", subcategory: nil)
    end_date   = Time.zone.today
    start_date = end_date - (days - 1).days

    buckets = (0...days).map { |i| [(start_date + i.days).to_date, []] }.to_h

    scope = @user.posts
                 .where(posted_at: start_date.beginning_of_day..end_date.end_of_day)
                 .where.not(mood: nil)

    scope = scope.where(category: category) if category.present? && category != "all"
    scope = scope.where(subcategory: subcategory) if subcategory.present?

    scope.find_each do |post|
      d = post.posted_at.to_date
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
