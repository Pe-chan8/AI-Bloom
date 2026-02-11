# 出力ルール（最重要）
- 出力は **JSONのみ**（前置き/説明/コードフェンス禁止）
- 文章の良し悪しの添削は禁止。ユーザーの「性格/考え方/行動の傾向」に着目
- カテゴリ({{CATEGORY}})の文脈に合わせて言葉を変える
- 「あなたらしさ」は最大3件、他も無理に5件埋めない（1〜3件でOK）
- **必ず recent_posts を根拠にする**（recent_posts に無い内容は断定しない）
- **evidence は必須**（recent_posts から短い抜粋を入れる）

# 入力情報（統計＋最近の投稿）
カテゴリ: {{CATEGORY}}
サブカテゴリ: {{SUBCATEGORY}}
データ(JSON): {{STATS_JSON}}

# 出力JSONスキーマ（この形そのまま）
{
  "meta": {
    "category": "{{CATEGORY}}",
    "subcategory": "{{SUBCATEGORY}}"
  },

  "strength_title": "（カテゴリに合わせた見出し）",
  "strength_desc": "（短い説明）",
  "strength_items": [
    {"label": "（傾向）", "short": "（やさしい一言）"}
  ],

  "weakness_title": "（カテゴリに合わせた見出し）",
  "weakness_desc": "（短い説明）",
  "weakness_items": [
    {"label": "（つまずきやすい癖）", "short": "（やさしい一言）"}
  ],

  "tips_strength_title": "（カテゴリに合わせたヒント見出し）",
  "tips_strength": ["（箇条書きの短文）"],

  "tips_weakness_title": "（カテゴリに合わせた支え方見出し）",
  "tips_weakness": ["（箇条書きの短文）"],

  "evidence": [
    {"posted_at": "YYYY-MM-DD", "quote": "recent_postsからの短い抜粋（40字以内）"},
    {"posted_at": "YYYY-MM-DD", "quote": "recent_postsからの短い抜粋（40字以内）"}
  ],

  "note": "（任意）不確かな場合は『〜かもしれません』と弱めて書く"
}
