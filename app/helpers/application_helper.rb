module ApplicationHelper
  def current_bottom_nav_partial
    return "new" if devise_controller?

    case controller_name
    when "top"
      "main"      # => shared/nav/_main.html.erb
    when "diagnoses"
      "diagnosis" # => shared/nav/_diagnosis.html.erb
    when "buddies"
      "buddies"
    when "posts"
      "posts"
    when "others"
      "others"
    else
      nil         # 何も出さない
    end
  end
end
