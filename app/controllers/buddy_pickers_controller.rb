class BuddyPickersController < ApplicationController
  before_action :authenticate_user!

  def show
    # 初期表示用
    @result = nil
  end

  def random
    buddy = Buddy.where(is_active: true).order(Arel.sql("RANDOM()")).first
    return redirect_to buddy_picker_path, alert: "バディが見つかりませんでした。" if buddy.blank?

    current_user.update!(buddy: buddy)
    current_user.update!(onboarded_at: Time.current) unless current_user.onboarded?

    redirect_to buddies_path, notice: "ランダムで「#{buddy.name}」を選びました！"
  end

  def recommend
    @result = BuddyPickerService.new(params: recommend_params).call
    render :show, status: :ok
  end

  private

  def recommend_params
    params.permit(:q1, :q2, :q3)
  end
end
