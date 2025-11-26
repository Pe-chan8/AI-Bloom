class BuddiesController < ApplicationController
  before_action :authenticate_user!

  def index
    @buddies = Buddy.where(is_active: true)
  end

  def select
    buddy = Buddy.find(params[:id])

    current_user.update!(buddy: buddy)

    redirect_to root_path, notice: "#{buddy.name} をバディに設定しました。"
  end

  private

  def current_buddy
    current_user.buddy
  end
  helper_method :current_buddy
end
