module StrengthDimension
  # key はDB保存/集計用（将来軸を増やしても壊れにくい）
  DEFINITIONS = {
    empathy:      { label: "共感力" },
    persistence:  { label: "継続" },
    challenge:    { label: "挑戦" },
    analysis:     { label: "分析" },
    expression:   { label: "表現" }
  }.freeze

  def self.keys = DEFINITIONS.keys
  def self.labels = DEFINITIONS.values.map { _1[:label] }
end
