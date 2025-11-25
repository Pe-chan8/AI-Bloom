class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  helper_method :current_buddy

  private

  def current_buddy
    return @current_buddy if defined?(@current_buddy)

    @current_buddy =
      if current_user&.buddy
        current_user.buddy
      else
        Buddy.find_by(code: "normal")
      end
  end
end
