class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, only: %i[edit update destroy]
  before_action :authorize_post!, only: %i[edit update destroy]
  before_action :set_bottom_nav

  def index
    @q = current_user.posts.ransack(params[:q])
    scope = @q.result

    if params[:date].present?
      d = Date.parse(params[:date])
      scope = scope.where(posted_at: d.beginning_of_day..d.end_of_day)
    end

    if params[:category].present? && params[:category] != "all"
      scope = scope.where(category: params[:category])
    end

    if params[:subcategory].present?
      scope = scope.where(subcategory: params[:subcategory])
    end

    @posts = scope.order(posted_at: :desc).page(params[:page])

    post_ids = @posts.map(&:id)
    @favorite_post_ids = current_user.favorites.where(post_id: post_ids).pluck(:post_id)
  end

  def show
    redirect_to buddy_talk_topic_path(params[:id]), status: :moved_permanently
  end

  def edit; end

  def update
    @post.tags_text = Array(params.dig(:post, :tag_list)).join(", ")

    if @post.update(post_params_without_body)
      redirect_to buddy_talk_topic_path(@post), notice: "投稿を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy!
    redirect_to posts_path, notice: "投稿を削除しました"
  end

  private

  def set_post
    @post = current_user.posts.find(params[:id])
  end

  def authorize_post!
    redirect_to root_path, alert: "この投稿は編集できません" if @post.user_id != current_user.id
  end

  def post_params
    params.require(:post).permit(
      :mood, :visibility, :posted_at, :title,
      :category, :subcategory,
      :tags_text
    )
  end

  def post_params_without_body
    params.require(:post).permit(
      :mood, :visibility, :posted_at, :title,
      :tags_text, :category, :subcategory
    )
  end

  def set_bottom_nav
    @bottom_nav_key = "posts"
  end
end
