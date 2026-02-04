class BuddyMessage < ApplicationRecord
  belongs_to :user
  belongs_to :post

  enum :role, { user: 0, ai: 1 }, default: :user

  validates :content, presence: true
end
