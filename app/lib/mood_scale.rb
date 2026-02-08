module MoodScale
  # Post enum: very_negative(0) .. very_positive(4)
  # グラフ用: 1..5 に変換
  MAP = {
    "very_negative" => 1,
    "negative"      => 2,
    "neutral"       => 3,
    "positive"      => 4,
    "very_positive" => 5
  }.freeze

  def self.score(value)
    return nil if value.nil?

    # enum の戻りは通常 String（"very_positive"）なのでまず文字列で引く
    key = value.to_s
    return MAP[key] if MAP.key?(key)

    # まれに整数が来る/DB値が来るケース（0..4 or 1..5）
    if value.is_a?(Integer)
      return (value + 1).clamp(1, 5) if value.between?(0, 4) # 0..4 を 1..5 に
      return value.clamp(1, 5)
    end

    # "0".."4" みたいな文字列も拾う
    if key.match?(/\A\d+\z/)
      n = key.to_i
      return (n + 1).clamp(1, 5) if n.between?(0, 4)
      return n.clamp(1, 5)
    end

    nil
  end
end
