class Post < ApplicationRecord
  belongs_to :user

  enum mood: {
    positive: 0,
    neutral: 1,
    negative: 2
  }, _prefix: true

  enum visibility: {
    private_post: 0,
    public_post: 1
  }, _prefix: true

  validates :body, presence: true, length: { maximum: 500 }
  validates :visibility, presence: true
end
