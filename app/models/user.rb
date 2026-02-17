class User < ApplicationRecord
  # -------------------------------------------------------
  # devise モジュール
  # -------------------------------------------------------
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  # -------------------------------------------------------
  # OmniAuth からユーザーを作成/取得
  # -------------------------------------------------------
  def self.from_omniauth(auth)
    user = find_or_initialize_by(provider: auth.provider, uid: auth.uid)

    # 既存ユーザー（メール一致）をGoogle連携に寄せたい場合
    if user.new_record? && auth.info.email.present?
      email_user = find_by(email: auth.info.email)
      if email_user
        email_user.update!(provider: auth.provider, uid: auth.uid)

        # nicknameが空だった時の保険（過去データ対策）
        if email_user.nickname.blank?
          email_user.update!(nickname: build_nickname_from_auth(auth))
        end

        return email_user
      end
    end

    user.email = auth.info.email if user.email.blank?

    # nickname 必須対策（Googleログインでも必ず入るようにする）
    user.nickname = build_nickname_from_auth(auth) if user.nickname.blank?

    # password必須バリデーション回避（validatable前提）
    user.password = Devise.friendly_token[0, 20] if user.encrypted_password.blank?

    user.save!
    user
  end

  def self.build_nickname_from_auth(auth)
    auth.info.name.presence ||
      auth.info.email.to_s.split("@").first.presence ||
      "user_#{SecureRandom.hex(4)}"
  end
  private_class_method :build_nickname_from_auth

  # -------------------------------------------------------
  # アソシエーション
  # -------------------------------------------------------
  has_many :posts, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorite_posts, through: :favorites, source: :post
  has_many :ai_messages, dependent: :destroy
  has_many :ai_message_feedbacks, dependent: :destroy

  # Buddy との関連付け（NULL 許可）
  belongs_to :buddy, optional: true

  # -------------------------------------------------------
  # ソーシャルタイプ診断のタイプ一覧
  # -------------------------------------------------------
  SOCIAL_TYPES = %w[expressive driving amiable analytical].freeze
  BUDDY_TYPES  = %w[expressive driving amiable analytical].freeze
  DOMINANT_TYPES = %w[expressive driving amiable analytical].freeze

  # -------------------------------------------------------
  # バリデーション
  # -------------------------------------------------------
  validates :social_type,
            inclusion: { in: SOCIAL_TYPES },
            allow_nil: true

  validates :recommended_buddy_type,
            inclusion: { in: BUDDY_TYPES },
            allow_nil: true

  validates :dominant_type,
            inclusion: { in: DOMINANT_TYPES },
            allow_nil: true

  validates :nickname,
            presence: true,
            length: { maximum: 30 }

  # -------------------------------------------------------
  # 現在のバディを返すヘルパー
  # -------------------------------------------------------
  def current_buddy
    buddy || Buddy.find_by(code: "normal")
  end

  # -------------------------------------------------------
  # オンボーディング完了判定
  # -------------------------------------------------------
  def onboarded?
    onboarded_at.present?
  end
end
