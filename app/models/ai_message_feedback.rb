class AiMessageFeedback < ApplicationRecord
  belongs_to :ai_message
  belongs_to :user

  # 👍=1 / 👎=-1 だけ許可
  validates :value, inclusion: { in: [ -1, 1 ] }
  # 同じユーザーは同じメッセージを1回だけ評価
  validates :user_id, uniqueness: { scope: :ai_message_id }

  def positive?
    value == 1
  end

  def negative?
    value == -1
  end
end
