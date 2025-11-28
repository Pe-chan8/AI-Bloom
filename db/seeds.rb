DiagnosisQuestion.destroy_all

questions = [
  # Amiable
  { position: 1,  content: "困っている人がいると、自分の予定を変えてでも手を差し伸べたくなることがある。", category: "amiable" },
  { position: 2,  content: "本当は違う意見を持っていても、その場の空気を乱したくなくて言わないことがある。", category: "amiable" },
  { position: 3,  content: "誰かに感謝されると、「もっと力になりたい」と思う自分がいる。", category: "amiable" },

  # Analytical
  { position: 4,  content: "決めごとは、感情より「根拠」「情報量」「確度」で判断したいほうだ。", category: "analytical" },
  { position: 5,  content: "何かを始める前に、できるだけ「最悪のシナリオ」も想定しておきたい。", category: "analytical" },
  { position: 6,  content: "人から相談されたとき、まず状況の整理から入ってしまうことが多い。", category: "analytical" },

  # Expressive
  { position: 7,  content: "話しているうちに、アイデアが湧いてきて話題がどんどん広がることがある。", category: "expressive" },
  { position: 8,  content: "落ち込んでいる人を見ると、つい気持ちを明るくする言葉をかけたくなる。", category: "expressive" },
  { position: 9,  content: "テンションが上がると、ついつい身振り手振りやリアクションが大きくなってしまう。", category: "expressive" },

  # Driving
  { position: 10, content: "やるべきことが明確になると、つい他の予定よりも優先して動きたくなる。", category: "driving" },
  { position: 11, content: "曖昧な状態が続くより、多少荒くても“結論を早く出す”方がスッキリする。", category: "driving" },
  { position: 12, content: "「できるかどうか」より「まずやってみる」が先にくることが多い。", category: "driving" }
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
