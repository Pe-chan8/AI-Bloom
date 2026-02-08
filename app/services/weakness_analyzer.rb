# app/services/weakness_analyzer.rb（置き場所に合わせて）
class WeaknessAnalyzer
  TOP_N = 5
  WeaknessItem = Struct.new(:label, :description, :evidence, keyword_init: true)

  def initialize(user)
    @user = user
  end

  # #58/#59 と同じ形の統一インターフェース
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
    "つまずきやすいポイント"
  end

  def default_evidence
    "（会話の中で印象的だった一文が入ります）"
  end
end
