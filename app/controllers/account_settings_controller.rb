class AccountSettingsController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(account_setting_params)
      redirect_to account_setting_path, notice: "ニックネームを更新しました"
    else
      flash.now[:alert] = "ニックネームを更新できませんでした"
      render :show, status: :unprocessable_entity
    end
  end

  private

  def account_setting_params
    params.require(:user).permit(:nickname)
  end
end
