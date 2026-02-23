class Analyses::SocialTypeResultsController < ApplicationController
  before_action :authenticate_user!

  def index
    @results = current_user.social_type_results.order(diagnosed_at: :desc)
  end

  def show
    @result = current_user.social_type_results.find(params[:id])
  end
end
