class AccountSettingsController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
  end

  def update
    @user = current_user

    case params[:kind]
    when "nickname"
      if @user.update(nickname_params)
        redirect_to account_setting_path, notice: "ニックネームを更新しました"
      else
        render :show, status: :unprocessable_entity
      end

    when "email"
      handle_email_change!

    else
      redirect_to account_setting_path, alert: "更新内容を確認してください"
    end
  end

  private

  def handle_email_change!
    new_email = email_params[:email].to_s.strip
    current_password = email_params[:current_password].to_s

    unless @user.valid_password?(current_password)
      @user.errors.add(:current_password, "が正しくありません")
      flash.now[:alert] = "メールアドレスを更新できませんでした"
      return render :show, status: :unprocessable_entity
    end

    if new_email.blank?
      @user.errors.add(:email, "を入力してください")
      flash.now[:alert] = "メールアドレスを更新できませんでした"
      return render :show, status: :unprocessable_entity
    end

    if new_email == @user.email
      return redirect_to account_setting_path, alert: "メールアドレスが変更されていません"
    end

    # すでに確認待ちで、入力も同じ = 再送
    if @user.unconfirmed_email.present? && @user.unconfirmed_email == new_email
      @user.resend_confirmation_instructions
      return redirect_to account_setting_path, notice: "確認メールを再送しました。メール内のリンクから変更を完了してください"
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
