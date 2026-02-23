class SocialTypeResult < ApplicationRecord
  belongs_to :user

  enum :dominant_type, {
    amiable: 0,
    analytical: 1,
    driving: 2,
    expressive: 3
  }

  validates :schema_version, presence: true
  validates :dominant_type, presence: true
  validates :scores, presence: true
  validates :diagnosed_at, presence: true
end
