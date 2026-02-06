class StrengthAnalyzer
  TOP_N = 5

  StrengthItem = Struct.new(:label, :description, :evidence, keyword_init: true)

  def initialize(user)
    @user = user
  end

  # 表示用：StrongItem の配列
  def top_strengths
    # いまは仮データ（段階1でAI算出に置き換える）
    StrengthDimension.labels.first(TOP_N).map do |label|
      StrengthItem.new(
        label: label,
        description: default_description(label),
        evidence: default_evidence # 会話の引用が入ると「評価」感が下がる
      )
    end
  end

  private

  def default_description(label)
    case label
    when "共感力" then "相手の気持ちを汲み取り、安心できる空気を作りやすい"
    when "継続"   then "小さく積み上げて、形にしていくのが得意"
    when "挑戦"   then "新しいことにも一歩ずつ試せる"
    when "分析"   then "状況を整理して、次にやることを決められる"
    when "表現"   then "気持ちや考えを言葉にして伝えられる"
    else "あなたらしさが出やすいポイント"
    end
  end

  def default_evidence
    "（会話の中で印象的だった一文が入ります）"
  end
end
