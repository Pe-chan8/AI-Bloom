class ApplicationController < ActionController::Base
  before_action :set_default_nav_type
  before_action :configure_permitted_parameters, if: :devise_controller?

  # ログイン必須（public は除外）
  before_action :authenticate_user!, unless: :public_controller?

  # オンボーディング強制リダイレクト（Devise と public は除外）
  before_action :redirect_to_onboarding_if_needed, unless: :public_controller?

  helper_method :current_buddy, :bottom_nav_key

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up,        keys: [ :nickname ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :nickname ])
  end

  private

  # ログイン不要で見せる画面（+ Devise）
  def public_controller?
    return true if devise_controller?
    %w[top onboardings diagnoses].include?(controller_name)
  end

  def redirect_to_onboarding_if_needed
    # 超重要：Devise（ログイン/ログアウト/登録）では絶対に動かさない
    return if devise_controller?

    return unless user_signed_in?
    return if current_user.onboarded?
    return if controller_name == "onboardings"

    # オンボ完了のきっかけになる画面は通す
    return if controller_name.in?(%w[diagnoses buddies posts])

    redirect_to onboarding_path
  end

  def set_default_nav_type
    @nav_type = :main
  end

  def current_buddy
    return @current_buddy if defined?(@current_buddy)

    @current_buddy =
      if current_user&.buddy
        current_user.buddy
      else
        Buddy.find_by(code: "normal")
      end
  end

  def bottom_nav_key
    case controller_name
    when "diagnoses" then "diagnosis"
    when "buddies"   then "buddies"
    when "posts"     then "posts"
    when "others"    then "others"
    when "top"       then "main"
    else
      "main"
    end
  end
end
