module ApplicationHelper
  def current_bottom_nav_partial
    if user_signed_in?
      "signed_in"
    else
      "guest"
    end
  end
end
