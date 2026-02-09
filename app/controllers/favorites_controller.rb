class FavoritesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

  def create
    current_user.favorites.create!(post: @post)
    redirect_back fallback_location: posts_path, notice: "お気に入りに追加しました"
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    redirect_back fallback_location: posts_path
  end

  def destroy
    current_user.favorites.find_by!(post: @post).destroy!
    redirect_back fallback_location: posts_path, notice: "お気に入りを解除しました"
  end

  private

  def set_post
    @post = current_user.posts.find(params[:post_id])
  end
end
