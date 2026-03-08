class TopController < ApplicationController
  def index
    redirect_to onboarding_path and return unless user_signed_in?

    @top_message = TopMessageService.new(user: current_user).call
  end
end
