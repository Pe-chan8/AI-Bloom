class Buddy < ApplicationRecord
  has_many :users, foreign_key: :current_buddy_id, inverse_of: :current_buddy

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true

  scope :active, -> { where(is_active: true) }
end
