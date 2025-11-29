class OthersController < ApplicationController
  before_action :set_bottom_nav

  def index
  end

  private

  def set_bottom_nav
    @bottom_nav_key = "others"
  end
end
