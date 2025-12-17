class ApplicationController < ActionController::Base
  before_action :authenticate_user!, unless: :public_controller?
  before_action :set_default_nav_type
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :redirect_to_onboarding_if_needed

  helper_method :current_buddy, :bottom_nav_key

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up,        keys: [:nickname])
    devise_parameter_sanitizer.permit(:account_update, keys: [:nickname])
  end

  private

  # ログイン不要で見せる画面
  def public_controller?
    return true if devise_controller?

    %w[top onboardings diagnoses].include?(controller_name)
  end

  # オンボーディング制御
  def redirect_to_onboarding_if_needed
    # Deviseの処理中は介入しない
    return if devise_controller?

    return unless user_signed_in?
    return if current_user.onboarded?

    # オンボ画面は除外（無限ループ防止）
    return if controller_name == "onboardings"

    # 初回アクションとして許可する画面
    return if controller_name.in?(%w[diagnoses buddies posts])

    redirect_to onboarding_path
  end

  # ▼ デフォルトのナビ種別
  def set_default_nav_type
    @nav_type = :main
  end

  # ▼ 現在のバディ
  def current_buddy
    return @current_buddy if defined?(@current_buddy)

    @current_buddy =
      if current_user&.buddy
        current_user.buddy
      else
        Buddy.find_by(code: "normal")
      end
  end

  # ▼ ボトムナビ切り替え
  def bottom_nav_key
    case controller_name
    when "diagnoses" then "diagnosis"
    when "buddies"   then "buddies"
    when "posts"     then "posts"
    when "others"    then "others"
    when "top"       then "main"
    else "main"
    end
  end
end
