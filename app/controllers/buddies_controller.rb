class BuddiesController < ApplicationController
  before_action :authenticate_user!

  def index
    @buddies = Buddy.where(is_active: true)
  end

  def select
    buddy = Buddy.find(params[:id])

    profile = current_user.profile || current_user.build_profile
    profile.buddy = buddy
    profile.save!

    redirect_to root_path, notice: "#{buddy.name} をバディに設定しました。"
  end

  private

  def current_buddy
    current_user.profile&.buddy
  end
  helper_method :current_buddy
end
