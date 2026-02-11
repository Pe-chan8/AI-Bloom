class TopController < ApplicationController
  def index
    redirect_to onboarding_path unless user_signed_in?
  end
end
