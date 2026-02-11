class OnboardingsController < ApplicationController

  def welcome; end
  def about; end

  def complete
    authenticate_user!
    current_user.update!(onboarded_at: Time.current)
    redirect_to root_path, notice: "ようこそ！"
  end
end
