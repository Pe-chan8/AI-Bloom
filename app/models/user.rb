class User < ApplicationRecord
  # Devise モジュール
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  # -------------------------------------------------------
  # アソシエーション
  # -------------------------------------------------------
  has_many :posts, dependent: :destroy

  # -------------------------------------------------------
  # ソーシャルタイプ診断のタイプ一覧
  # -------------------------------------------------------
  SOCIAL_TYPES = %w[expressive driving amiable analytical].freeze
  BUDDY_TYPES  = %w[expressive driving amiable analytical].freeze

  # -------------------------------------------------------
  # バリデーション（任意だが入れておくと安全）
  # null を許容しつつ、値がある場合は型チェック
  # -------------------------------------------------------
  validates :social_type,
            inclusion: { in: SOCIAL_TYPES },
            allow_nil: true

  validates :recommended_buddy_type,
            inclusion: { in: BUDDY_TYPES },
            allow_nil: true
end
