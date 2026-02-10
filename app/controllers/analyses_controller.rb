class AnalysesController < ApplicationController
  before_action :authenticate_user!

  def show
    @category    = params[:category].presence || "all"
    @subcategory = params[:subcategory].presence

    # ▼ マスキングは別々に管理
    @show_weakness_items = params[:show_weakness_items].to_s == "1"
    @show_weakness_tips  = params[:show_weakness_tips].to_s == "1"

    # ▼ 今週（カテゴリ）
    week_start = Time.zone.today.beginning_of_week(:monday)
    week_end   = Time.zone.today.end_of_week(:monday)

    weekly_scope = current_user.posts
      .where(posted_at: week_start.beginning_of_day..week_end.end_of_day)
      .where.not(mood: nil)

    weekly_scope = weekly_scope.where(category: @category) if @category.present? && @category != "all"
    weekly_scope = weekly_scope.where(subcategory: @subcategory) if @subcategory.present?

    scores = weekly_scope.pluck(:mood).map { |m| MoodTrendAnalyzer::MoodScale.score(m) }.compact
    @weekly_mood_avg = scores.any? ? (scores.sum.to_f / scores.size).round(1) : nil
    @weekly_posts_count = weekly_scope.count

    # ▼ 直近14日
    @mood_daily_points = MoodTrendAnalyzer.new(current_user).daily_points(
      days: 14,
      category: @category,
      subcategory: @subcategory
    ) || []

    # ▼ サブカテゴリ表示用（上位10）※「表示だけ」にする
    posts_scope = current_user.posts.where.not(subcategory: [ nil, "" ])
    posts_scope = posts_scope.where(category: @category) unless @category == "all"
    @top_subcategories = posts_scope.group(:subcategory).order(Arel.sql("COUNT(*) DESC")).limit(10).count || {}

    # ▼ 仮データ（AI化するまで）
    @strength_items = [
      { label: "準備中", short: "少々お待ちください" },
      { label: "準備中", short: "少々お待ちください" },
      { label: "準備中", short: "少々お待ちください" },
      { label: "準備中", short: "少々お待ちください" },
      { label: "準備中", short: "少々お待ちください" }
    ]

    @weakness_items = [
      { label: "準備中", short: "少々お待ちください" },
      { label: "準備中", short: "少々お待ちください" },
      { label: "準備中", short: "少々お待ちください" },
      { label: "準備中", short: "少々お待ちください" },
      { label: "準備中", short: "少々お待ちください" }
    ]

    @tips_strength = [
      "少々お待ちください",
      "少々お待ちください",
      "少々お待ちください"
    ]
    @tips_weakness = [
      "少々お待ちください",
      "少々お待ちください",
      "少々お待ちください"
    ]

    @weekly_summary = WeeklyOneLineSummary.new(current_user).call(category: @category) || ""
  end
end
