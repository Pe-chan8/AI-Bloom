class User < ApplicationRecord
  # -------------------------------------------------------
  # devise モジュール
  # -------------------------------------------------------
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # -------------------------------------------------------
  # アソシエーション
  # -------------------------------------------------------
  has_many :posts, dependent: :destroy
  has_many :ai_messages, dependent: :destroy

  # Buddy との関連付け（NULL 許可）
  belongs_to :buddy, optional: true

  # -------------------------------------------------------
  # ソーシャルタイプ診断のタイプ一覧
  # -------------------------------------------------------
  SOCIAL_TYPES = %w[expressive driving amiable analytical].freeze
  BUDDY_TYPES  = %w[expressive driving amiable analytical].freeze

  # -------------------------------------------------------
  # バリデーション
  # -------------------------------------------------------
  validates :social_type,
            inclusion: { in: SOCIAL_TYPES },
            allow_nil: true

  validates :recommended_buddy_type,
            inclusion: { in: BUDDY_TYPES },
            allow_nil: true

  # -------------------------------------------------------
  # 現在のバディを返すヘルパー
  # （未設定なら code: "normal" のバディを返す）
  # -------------------------------------------------------
  def current_buddy
    buddy || Buddy.find_by(code: "normal")
  end
end
