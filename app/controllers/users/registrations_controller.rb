class Users::RegistrationsController < Devise::RegistrationsController
  before_action :strip_blank_nickname, only: :update

  private

  def strip_blank_nickname
    return unless params[:user].is_a?(ActionController::Parameters)
    params[:user].delete(:nickname) if params[:user][:nickname].blank?
  end
end
