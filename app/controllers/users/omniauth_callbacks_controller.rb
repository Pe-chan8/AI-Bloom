class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    auth = request.env["omniauth.auth"]
    user = User.from_omniauth(auth)

    sign_in_and_redirect user, event: :authentication
    set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn("[GoogleLogin] failed: #{e.message}")
    redirect_to new_user_session_path, alert: "Googleログインに失敗しました。もう一度お試しください。"
  end

  def failure
    redirect_to root_path, alert: "Googleログインがキャンセルされました。"
  end
end
