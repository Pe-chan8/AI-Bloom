# 出力ルール（最重要）
- 出力は **JSONのみ**（前置き/説明/コードフェンス禁止）
- 文章の添削は禁止。ユーザーの「性格/考え方/行動の傾向」に着目
- category=all は「総合」：カテゴリ横断の傾向として整理する
- 無理に件数を埋めない（各セクション1〜3件でOK）
- 断定しすぎず「〜かもしれません」を活用する

# 入力情報
カテゴリ: {{CATEGORY}}
サブカテゴリ: {{SUBCATEGORY}}
データ(JSON): {{STATS_JSON}}

# 出力JSONスキーマ（この形そのまま）
{
  "strength_title": "総合：あなたらしさ",
  "strength_desc": "（全体の傾向を短く）",
  "strength_items": [
    {"label": "（傾向）", "short": "（やさしい一言）"}
  ],

  "weakness_title": "総合：無理が溜まりやすいところ",
  "weakness_desc": "（全体の傾向を短く）",
  "weakness_items": [
    {"label": "（つまずきやすい癖）", "short": "（やさしい一言）"}
  ],

  "tips_strength_title": "総合：あなたの良さをそっと活かすヒント",
  "tips_strength": ["（箇条書きの短文）"],

  "tips_weakness_title": "総合：しんどいときのヒント",
  "tips_weakness": ["（箇条書きの短文）"]
}
