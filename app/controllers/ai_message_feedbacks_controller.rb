class AiMessageFeedbacksController < ApplicationController
  before_action :authenticate_user!

  def create
    ai_message = current_user.ai_messages.find(params[:ai_message_id])

    feedback = AiMessageFeedback.find_or_initialize_by(
      user: current_user,
      ai_message: ai_message
    )

    feedback.value = params[:value].to_i

    if feedback.save
      redirect_back fallback_location: post_path(ai_message.post),
                    notice: "AIバディへの評価を保存しました。"
    else
      redirect_back fallback_location: post_path(ai_message.post),
                    alert: "評価の保存に失敗しました。"
    end
  end
end
