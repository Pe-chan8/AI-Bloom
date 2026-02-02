class BuddyTalksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_bottom_nav

  def show
    @buddy = current_user.buddy
    @post  = current_user.posts.build(
      posted_at: Time.zone.now
    )
  end

  private

  def set_bottom_nav
    @bottom_nav_key = "buddy_talk"
  end
end
