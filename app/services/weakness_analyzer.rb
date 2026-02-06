class WeaknessAnalyzer
  TOP_N = 5

  WeaknessItem = Struct.new(
    :label,
    :description,
    :evidence,
    keyword_init: true
  )

  def initialize(user)
    @user = user
  end

  # Controller / View から使う統一インターフェース
  def top5
    top_weaknesses
  end

  def top_weaknesses
    WeaknessDimension.labels.first(TOP_N).map do |label|
      WeaknessItem.new(
        label: label,
        description: default_description(label),
        evidence: default_evidence
      )
    end
  end

  private

  def default_description(label)
    case label
    when "抱え込み" then "一人でなんとかしようとして、疲れが溜まりやすい"
    when "過集中"   then "考えすぎて決めきれなくなることがある"
    else "つまずきやすいポイント"
    end
  end

  def default_evidence
    "（会話の中で印象的だった一文が入ります）"
  end
end
