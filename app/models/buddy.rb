class Buddy < ApplicationRecord
  has_many :users, foreign_key: :current_buddy_id, inverse_of: :current_buddy

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true

  scope :active, -> { where(is_active: true) }

  # code → ニックネーム の対応表
  BUDDY_CODE_TO_NICKNAME = {
    "amiable"       => "ルナ",
    "analytical"    => "キエル",
    "expressive"    => "エルフィ",
    "driving"       => "ヴァル",
    "normal"        => "ニル",
    "kansai_friend" => "レオ"
  }.freeze

  # 画面で使う表示名
  def display_name
    BUDDY_CODE_TO_NICKNAME[code] || name
  end
end
