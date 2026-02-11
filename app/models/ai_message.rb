class AiMessage < ApplicationRecord
  belongs_to :user
  belongs_to :post,  optional: true
  belongs_to :buddy, optional: true

  has_many :ai_message_feedbacks, dependent: :destroy
  has_many :ai_logs, dependent: :destroy

  # kind: daily / weekly / reply / tip / analysis_feedback
  enum :kind, {
    daily:            0,
    weekly:           1,
    reply:            2,
    tip:              3,
    analysis_feedback: 4
  }, default: :reply

  enum :sentiment, {
    positive: 0,
    neutral:  1,
    negative: 2
  }, prefix: true
end
