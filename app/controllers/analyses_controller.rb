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
    posts_scope = current_user.posts.where.not(subcategory: [nil, ""])
    posts_scope = posts_scope.where(category: @category) unless @category == "all"
    @top_subcategories = posts_scope.group(:subcategory).order(Arel.sql("COUNT(*) DESC")).limit(10).count || {}

    # ▼ 仮データ（AI化するまで）
    @strength_items = [
      { label: "共感力", short: "誰かに寄り添うのが上手" },
      { label: "継続",   short: "小さく積み上げられる" },
      { label: "挑戦",   short: "一歩踏み出せる" },
      { label: "分析",   short: "状況整理が得意" },
      { label: "表現",   short: "言語化して伝えられる" }
    ]

    @weakness_items = [
      { label: "抱え込み",   short: "一人で背負いがち" },
      { label: "過集中",     short: "視野が狭くなりやすい" },
      { label: "自己否定",   short: "自分に厳しくなりがち" },
      { label: "遠慮しすぎ", short: "我慢が溜まりやすい" },
      { label: "反芻",       short: "考えがループしやすい" }
    ]

    @tips_strength = [
      "「できたこと」を1行でも記録して、再現性を増やす",
      "強みが出た場面に「サブカテゴリー」を付けて、後から見返しやすくする",
      "週1回、強みTOP1を意識して使う“日”を作る"
    ]
    @tips_weakness = [
      "苦手が出たら「事実 / 解釈 / 次の一手」を3分割でメモ",
      "抱え込み対策：相談先を“1人固定”しておく（迷わない）",
      "反芻対策：寝る前は“結論を出さない時間”を決める"
    ]

    @weekly_summary = WeeklyOneLineSummary.new(current_user).call(category: @category) || ""
  end
end
