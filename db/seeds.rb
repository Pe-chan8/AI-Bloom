DiagnosisQuestion.destroy_all

questions = [
  { position: 1,  content: "誰かが困っていると、自然と気づいて助けたくなる。", category: "amiable" },
  { position: 2,  content: "物事を決める前に、できるだけ情報を集めて比較したい。", category: "analytical" },
  { position: 3,  content: "新しいアイデアを考えたり、誰かと盛り上がる時間が好きだ。", category: "expressive" },
  { position: 4,  content: "目標が決まると、すぐに行動に移したくなる。", category: "driving" },
  { position: 5,  content: "相手の気持ちを考えすぎて、自分の意見を後回しにしてしまうことがある。", category: "amiable" },
  { position: 6,  content: "感情よりも、事実・データを優先して判断する方だ。", category: "analytical" },
  { position: 7,  content: "話していると、つい思いついたことを口にしてしまうことが多い。", category: "expressive" },
  { position: 8,  content: "結果がはっきりしない状況が続くと、ストレスを感じやすい。", category: "driving" },
  { position: 9,  content: "人との関係を大切にし、できるだけ衝突を避けたいと思う。", category: "amiable" },
  { position: 10, content: "予定や計画は、きちんと整理されている方が安心する。", category: "analytical" }
]

questions.each do |q|
  DiagnosisQuestion.create!(q)
end

puts "DiagnosisQuestion seeds created: #{DiagnosisQuestion.count}"
