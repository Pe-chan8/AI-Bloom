class OnboardingsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :welcome, :about ]
  skip_before_action :redirect_to_onboarding_if_needed, only: [ :welcome, :about, :complete ]

  def welcome; end
  def about; end

  def complete
    authenticate_user!
    current_user.update!(onboarded_at: Time.current)
    redirect_to root_path, notice: "ようこそ！"
  end
end
