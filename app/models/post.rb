class Post < ApplicationRecord
  belongs_to :user
  has_many :ai_messages, dependent: :destroy

  TAG_OPTIONS = %w[
    仕事
    学習
    就職活動
    転職
    婚活
    恋愛
    人間関係
    体調
    プライベート
    挑戦
    継続
    しんどい
    うれしい
    その他
  ].freeze

  # 気分：既存のまま（positive / neutral / negative）
  enum :mood, { positive: 0, neutral: 1, negative: 2 }, prefix: true

  # 公開範囲：private / public（既存のまま）
  enum :visibility, { private: 0, public: 1 }, prefix: true

  # ▼ バディ投稿MVP（#284）向け：最低限のバリデーション ▼
  validates :posted_at, presence: true
  validates :body, presence: true
  validates :title, length: { maximum: 60 }, allow_blank: true
  validates :tags_text, length: { maximum: 100 }, allow_blank: true

  # ▼ Ransack で検索可能にするカラムを許可 ▼
  def self.ransackable_attributes(_auth_object = nil)
    %w[
      body
      title
      tags_text
      posted_at
      created_at
      updated_at
      mood
      visibility
    ]
  end
end
