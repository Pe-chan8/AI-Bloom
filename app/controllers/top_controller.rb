class TopController < ApplicationController
  def index
    redirect_to onboarding_path and return unless user_signed_in?

    @top_message = TopMessageService.new(
      user: current_user,
      buddy: current_buddy
    ).call
  end
end
