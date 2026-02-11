class Users::SessionsController < Devise::SessionsController
  protected

  def after_sign_out_path_for(_resource_or_scope)
    onboarding_path
  end
end
