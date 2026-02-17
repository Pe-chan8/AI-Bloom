class AccountSettingsController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
  end

  def update
    @user = current_user

    if params[:commit_target] == "email"
      handle_email_change!
      return
    end

    if @user.update(nickname_params)
      redirect_to account_setting_path, notice: "ニックネームを更新しました"
    else
      flash.now[:alert] = "ニックネームを更新できませんでした"
      render :show, status: :unprocessable_entity
    end
  ensure
    Rails.logger.debug("ACCOUNT_SETTING update target=#{params[:commit_target]} errors=#{@user&.errors&.full_messages}")
    Rails.logger.debug("email now=#{@user&.email} unconfirmed_email=#{@user&.try(:unconfirmed_email)}")
  end

  private

  def handle_email_change!
    new_email = email_params[:email].to_s.strip
    current_password = email_params[:current_password].to_s

    if new_email.blank?
      @user.errors.add(:email, "を入力してください")
      flash.now[:alert] = "メールアドレスを更新できませんでした"
      render :show, status: :unprocessable_entity
      return
    end

    unless @user.valid_password?(current_password)
      @user.errors.add(:current_password, "が正しくありません")
      flash.now[:alert] = "メールアドレスを更新できませんでした"
      render :show, status: :unprocessable_entity
      return
    end

    if @user.update(email: new_email)
      redirect_to account_setting_path, notice: "確認メールを送信しました。メール内のリンクから変更を完了してください"
    else
      flash.now[:alert] = "メールアドレスを更新できませんでした"
      render :show, status: :unprocessable_entity
    end
  end

  def nickname_params
    params.require(:user).permit(:nickname)
  end

  def email_params
    params.require(:user).permit(:email, :current_password)
  end
end
