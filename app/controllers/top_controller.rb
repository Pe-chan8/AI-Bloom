class TopController < ApplicationController
  skip_before_action :redirect_to_onboarding_if_needed

  def index
    redirect_to onboarding_path unless user_signed_in?
  end
end
