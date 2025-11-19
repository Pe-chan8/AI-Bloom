DiagnosisQuestion.destroy_all

questions = [
  { position: 1, content: "初めて会う人とも、比較的すぐに打ち解けられる方だ。" },
  { position: 2, content: "大人数の場よりも、少人数でじっくり話す方が落ち着く。" },
  { position: 3, content: "話すよりも、聞き役にまわることが多い。" },
  { position: 4, content: "予定はきっちり決めてから動きたいタイプだ。" },
  { position: 5, content: "その場の雰囲気で、直感的に動くことが多い。" },
  { position: 6, content: "感情よりも、事実やデータを重視して考える。" },
  { position: 7, content: "相手の気持ちを想像しながら、言葉を選ぶことが多い。" },
  { position: 8, content: "一人の時間がないと、少し疲れてしまうと感じる。" },
  { position: 9, content: "人から相談されることが多いと感じる。" },
  { position: 10, content: "“みんなでワイワイ”より、“落ち着いた安心できる空間”が好きだ。" }
]

questions.each do |q|
  DiagnosisQuestion.create!(q)
end

puts "DiagnosisQuestion seeds created: #{DiagnosisQuestion.count}"
