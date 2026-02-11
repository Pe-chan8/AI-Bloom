class AnalyticsController < ApplicationController
  before_action :authenticate_user!

  ANALYSIS_TTL = 24.hours
  ANALYSIS_MIN_POSTS_14D = 2 # このカテゴリの直近14日投稿が2件未満なら「データ不足」でAI生成しない

  def show
    @category    = params[:category].presence || "all"
    @subcategory = params[:subcategory].presence

    # ▼ マスキングは別々に管理
    @show_weakness_items = params[:show_weakness_items].to_s == "1"
    @show_weakness_tips  = params[:show_weakness_tips].to_s == "1"

    # ▼ 今週 / 先週 / 合計（カテゴリ＆サブカテゴリ込み）
    progress = WeeklyOneLineSummary.new(current_user).call(category: @category, subcategory: @subcategory)
    @two_weeks_total_posts_count    = progress[:total][:posts_count]
    @this_week_posts_count          = progress[:this_week][:posts_count]
    @this_week_mood_avg             = progress[:this_week][:mood_avg]
    @this_week_top_word             = progress[:this_week][:top_word]
    @last_week_posts_count          = progress[:last_week][:posts_count]
    @last_week_mood_avg             = progress[:last_week][:mood_avg]
    @last_week_top_word             = progress[:last_week][:top_word]
    @weekly_summary_category_label  = progress[:category_label]

    # ▼ 今週（カテゴリ）…（既存の weekly_mood_avg / weekly_posts_count を使っている箇所があるなら残す）
    week_range = this_week_range
    weekly_scope = posts_scope_in_range(week_range[:from], week_range[:to], category: @category, subcategory: @subcategory)
                  .where.not(mood: nil)

    scores = weekly_scope.pluck(:mood).map { |m| ::MoodScale.score(m) }.compact
    @weekly_mood_avg    = scores.any? ? (scores.sum.to_f / scores.size).round(1) : nil
    @weekly_posts_count = weekly_scope.count

    # ▼ 直近14日（グラフ）
    @mood_daily_points = MoodTrendAnalyzer.new(current_user).daily_points(
      days: 14,
      category: @category,
      subcategory: @subcategory
    ) || []

    # ▼ サブカテゴリ表示用（上位10）
    @top_subcategories = top_subcategories_for(@category)

    # ▼ 分析に使える投稿数（カテゴリごと）
    @analysis_posts_count_14d = analysis_posts_count_14d(category: @category, subcategory: @subcategory)
    @analysis_data_insufficient = @analysis_posts_count_14d < ANALYSIS_MIN_POSTS_14D

    if @analysis_data_insufficient
      @analysis_feedback = nil
      set_empty_analysis
    else
      # カテゴリを押しただけで「必要なら」AI生成
      @analysis_feedback = find_or_generate_feedback!(category: @category, subcategory: @subcategory)
      apply_analysis_payload(@analysis_feedback)
    end
  end

  # 「今すぐ更新」ボタン用（手動更新）
  def generate_feedback
    category    = params[:category].presence || "all"
    subcategory = params[:subcategory].presence

    posts_count = analysis_posts_count_14d(category: category, subcategory: subcategory)
    if posts_count < ANALYSIS_MIN_POSTS_14D
      redirect_to analytics_path(category: category, subcategory: subcategory),
                  alert: "このカテゴリはまだデータが少ないため、分析を作成できません。投稿が増えたらお試しください。"
      return
    end

    result = Ai::AnalysisFeedbackGenerator.new(current_user).call(category: category, subcategory: subcategory)

    if result.success?
      redirect_to analytics_path(category: category, subcategory: subcategory),
                  notice: "分析を更新しました！"
    else
      redirect_to analytics_path(category: category, subcategory: subcategory),
                  alert: "分析の生成に失敗しました。時間をおいて再度お試しください。"
    end
  end

  private

  def this_week_range
    end_date   = Time.zone.today.end_of_week(:monday)
    start_date = end_date.beginning_of_week(:monday)
    { from: start_date.beginning_of_day, to: end_date.end_of_day }
  end

  def last_week_range
    end_date   = (Time.zone.today - 7.days).end_of_week(:monday)
    start_date = end_date.beginning_of_week(:monday)
    { from: start_date.beginning_of_day, to: end_date.end_of_day }
  end

  # posted_at ベース（分析と統一）
  def posts_scope_in_range(from_time, to_time, category:, subcategory:)
    scope = current_user.posts.where(posted_at: from_time..to_time)
    scope = scope.where(category: category) if category.present? && category != "all"
    scope = scope.where(subcategory: subcategory) if subcategory.present?
    scope
  end

  def analysis_posts_count_14d(category:, subcategory:)
    end_date   = Time.zone.today
    start_date = end_date - 13.days

    scope = current_user.posts.where(posted_at: start_date.beginning_of_day..end_date.end_of_day)
    scope = scope.where(category: category) if category.present? && category != "all"
    scope = scope.where(subcategory: subcategory) if subcategory.present?
    scope.count
  end

  def top_subcategories_for(category)
    posts_scope = current_user.posts.where.not(subcategory: [ nil, "" ])
    posts_scope = posts_scope.where(category: category) unless category == "all"
    posts_scope.group(:subcategory).order(Arel.sql("COUNT(*) DESC")).limit(10).count || {}
  end

  def set_empty_analysis
    @strength_title = "あなたらしさ"
    @strength_desc  = nil
    @weakness_title = "無理が溜まりやすいところ"
    @weakness_desc  = nil
    @tips_strength_title = "あなたの良さをそっと活かすヒント"
    @tips_weakness_title = "しんどいときのヒント"

    @strength_items = []
    @weakness_items = []
    @tips_strength  = []
    @tips_weakness  = []
  end

  # DBの category/subcategory で確実に取得し、TTLで自動生成（常に1件に保つ）
  def find_or_generate_feedback!(category:, subcategory:)
    category    = category.presence || "all"
    subcategory = subcategory.presence

    scope = current_user.ai_messages.where(kind: :analysis_feedback, category: category.to_s)
    scope = subcategory.present? ? scope.where(subcategory: subcategory) : scope.where(subcategory: nil)

    latest = scope.order(created_at: :desc).first
    scope.where.not(id: latest.id).delete_all if latest.present?

    return latest if latest.present? && latest.created_at > ANALYSIS_TTL.ago

    result = Ai::AnalysisFeedbackGenerator.new(current_user).call(category: category, subcategory: subcategory)
    return latest unless result.success?

    newest = scope.reorder(created_at: :desc).first
    scope.where.not(id: newest.id).delete_all if newest.present?
    newest
  end

  def apply_analysis_payload(ai_message)
    payload = parse_analysis_payload(ai_message&.content)

    # labels ラップ形式にも対応（{"labels":{...}, ...}）
    labels = payload["labels"].is_a?(Hash) ? payload["labels"] : {}
    payload = labels.merge(payload.except("labels"))

    items_root = payload["items"].is_a?(Hash) ? payload["items"] : {}
    tips_root  = payload["tips"].is_a?(Hash)  ? payload["tips"]  : {}

    @strength_title = payload["strength_title"] || "あなたらしさ"
    @strength_desc  = payload["strength_desc"]

    @weakness_title = payload["weakness_title"] || "無理が溜まりやすいところ"
    @weakness_desc  = payload["weakness_desc"]

    @tips_strength_title = payload["tips_strength_title"] || "あなたの良さをそっと活かすヒント"
    @tips_weakness_title = payload["tips_weakness_title"] || "しんどいときのヒント"

    strength_raw =
      payload["strength_items"] ||
      items_root["strength_items"] ||
      items_root["strength"]

    weakness_raw =
      payload["weakness_items"] ||
      items_root["weakness_items"] ||
      items_root["weakness"]

    tips_strength_raw =
      payload["tips_strength"] ||
      tips_root["strength"]

    tips_weakness_raw =
      payload["tips_weakness"] ||
      tips_root["weakness"]

    @strength_items = normalize_items(strength_raw) || []
    @weakness_items = normalize_items(weakness_raw) || []

    # 無理に埋めない（最大3）
    @strength_items = Array(@strength_items).first(3)
    @weakness_items = Array(@weakness_items).first(3)

    @tips_strength  = normalize_tips(tips_strength_raw) || []
    @tips_weakness  = normalize_tips(tips_weakness_raw) || []
  end

  def parse_analysis_payload(content)
    return {} if content.blank?
    JSON.parse(content)
  rescue JSON::ParserError
    {}
  end

  def normalize_items(raw)
    return nil unless raw.is_a?(Array)

    items = raw.filter_map do |h|
      next unless h.is_a?(Hash)
      label = (h["label"] || h[:label]).to_s.strip
      short = (h["short"] || h[:short]).to_s.strip
      next if label.blank? && short.blank?
      { label: label.presence || "ポイント", short: short.presence || "" }
    end

    items.presence
  end

  def normalize_tips(raw)
    return nil unless raw.is_a?(Array)

    tips = raw.filter_map do |t|
      s = t.to_s.strip
      s.presence
    end

    tips.presence
  end
end
