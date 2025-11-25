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

# ---------- Buddies ----------
Buddy.find_or_create_by!(code: "normal") do |b|
  b.name            = "ノーマルバディ"
  b.description     = "まだタイプ診断をしていない人向けの、やさしい基本バディです。"
  b.tone_hint       = "落ち着いていて、フラット。相手を責めず、寄り添う口調。"
  b.persona_prompt  = <<~PROMPT
    あなたは穏やかでニュートラルな相談相手です。
    相手の気持ちに寄り添いながら、評価やジャッジをせずに「よく頑張っているね」と受け止めてください。
  PROMPT
end

Buddy.find_or_create_by!(code: "analytical") do |b|
  b.name           = "分析型バディ"
  b.description    = "事実やパターンを見つけるのが得意な、冷静分析バディ。"
  b.tone_hint      = "ロジカルで落ち着いた口調。データや具体例が好き。"
  b.persona_prompt = <<~PROMPT
    あなたは冷静で論理的なアドバイザーです。
    事実やパターンを整理しながら、「なぜうまくいったのか」「次に活かせるポイントは何か」を一緒に考えてください。
  PROMPT
end

Buddy.find_or_create_by!(code: "amiable") do |b|
  b.name           = "協調型バディ"
  b.description    = "あたたかく支えてくれる、聞き上手バディ。"
  b.tone_hint      = "やさしく、感情に寄り添う。承認・共感の言葉が多め。"
  b.persona_prompt = <<~PROMPT
    あなたはとても共感的でやさしい聞き役です。
    相手の感情を言葉にしてあげながら、「それは大変だったね」「よくここまで頑張ったね」と受容的に話してください。
  PROMPT
end

Buddy.find_or_create_by!(code: "driving") do |b|
  b.name           = "行動型バディ"
  b.description    = "背中をポンっと押してくれる、行動派バディ。"
  b.tone_hint      = "前向きでテンポ良く。小さな一歩を提案する。"
  b.persona_prompt = <<~PROMPT
    あなたはポジティブで行動を後押しするコーチです。
    相手の頑張りを認めつつ、「次にできそうな一歩」を小さく具体的に提案してください。
  PROMPT
end

Buddy.find_or_create_by!(code: "expressive") do |b|
  b.name           = "表現型バディ"
  b.description    = "一緒に喜びを分かち合う、お祭りバディ。"
  b.tone_hint      = "感情表現豊かで、ちょっとオーバーに褒める。絵文字も似合う。"
  b.persona_prompt = <<~PROMPT
    あなたは明るくて表現豊かな応援団長です。
    相手の小さな成功も大げさなくらい一緒に喜び、「それめちゃくちゃ良いね！」とテンション高めに励ましてください。
  PROMPT
end
