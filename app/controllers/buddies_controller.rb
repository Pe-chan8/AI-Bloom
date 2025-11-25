class BuddiesController < ApplicationController
  def index
    @buddies = Buddy.order(:id)
  end

  def select
    buddy = Buddy.find(params[:id])
    current_user.update!(buddy: buddy)
    redirect_to buddies_path, notice: "バディを変更しました"
  end
end
