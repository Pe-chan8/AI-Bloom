class ApplicationController < ActionController::Base
  include MetaTags::ControllerHelper

  before_action :set_default_nav_type
  before_action :configure_permitted_parameters, if: :devise_controller?

  # meta-tags（全ページ共通の初期値）
  before_action :set_default_meta_tags

  # ログイン必須（public は除外）
  before_action :authenticate_user!, unless: :public_controller?

  # 互換性のため “この名前” を残す（他controllerの skip_before_action が参照している）
  before_action :redirect_to_onboarding_if_needed, unless: :public_controller?

  helper_method :current_buddy, :bottom_nav_key

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up,        keys: [ :nickname ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :nickname ])
  end

  # -------------------------
  # meta-tags（共通）
  # -------------------------
  def set_default_meta_tags
    set_meta_tags(
      site: "AI-Bloom",
      title: "AI-Bloom",
      description: "日々の小さな頑張りを、AIバディと一緒にやさしく振り返るアプリ",
      viewport: "width=device-width, initial-scale=1",
      og: {
        type: "website",
        site_name: "AI-Bloom"
      },
      twitter: {
        card: "summary_large_image"
      }
    )
  end

  private

  # ログイン不要で見せる画面（+ Devise）
  # ※「未ログインはオンボに飛ぶ」方針なので、ここは最小限にする
  def public_controller?
    return true if devise_controller?
    %w[top onboardings diagnoses].include?(controller_name)
  end

  # 未ログインだけオンボへ（ログイン済みは一切ブロックしない）
  def redirect_to_onboarding_if_needed
    return if devise_controller?
    return if controller_name == "onboardings"
    return if controller_name == "diagnoses"
    return if user_signed_in?

    return if request.path == onboarding_path # 念のため（ループ防止）

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
