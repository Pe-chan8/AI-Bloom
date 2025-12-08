class AiLog < ApplicationRecord
  belongs_to :user
  belongs_to :post,       optional: true
  belongs_to :ai_message, optional: true

  # Rails 7.1+ / 8 系の新しい enum シンタックス
  enum :status, {
    success: "success",
    error:   "error"
  }, suffix: true

  validates :provider, :model, :status, presence: true
end
