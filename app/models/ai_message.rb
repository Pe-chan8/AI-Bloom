class AiMessage < ApplicationRecord
  belongs_to :user
  belongs_to :post,  optional: true
  belongs_to :buddy, optional: true

  # kind: daily / weekly / reply
  enum :kind, {
    daily:  0,
    weekly: 1,
    reply:  2
  }

  # sentiment: 今は使わなくてもOK
  enum :sentiment, {
    positive: 0,
    neutral:  1,
    negative: 2
  }
end
