class AccountsController < ApplicationController
  before_action :authenticate_user!

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(account_params)
      redirect_to edit_account_path, notice: "ニックネームを更新しました"
    else
      flash.now[:alert] = "ニックネームを更新できませんでした"
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.require(:user).permit(:nickname)
  end
end
