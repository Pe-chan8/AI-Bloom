class Users::SessionsController < Devise::SessionsController
  skip_before_action :redirect_to_onboarding_if_needed, only: [:destroy]

  protected

  def after_sign_out_path_for(_resource_or_scope)
    onboarding_path
  end
end
