class BuddiesController < ApplicationController
  before_action :authenticate_user!

  before_action :set_buddy, only: :select

  def index
    @buddies = Buddy.where(is_active: true)
  end

  # バディ変更
  def select
    current_user.update!(buddy: @buddy)

    # ▼ 初回の「何かした」扱いにする（オンボーディング完了）
    current_user.update!(onboarded_at: Time.current) unless current_user.onboarded?

    redirect_to buddies_path, notice: "#{@buddy.display_name} にバディを変更しました。"
  end

  private

  def set_buddy
    @buddy = Buddy.find(params[:id])
  end
end
