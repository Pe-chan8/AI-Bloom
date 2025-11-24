class PostsController < ApplicationController
  before_action :authenticate_user!

  def new
    @post = Post.new
    render partial: "form", locals: { post: @post }, layout: false
  end

  def create
    @post = current_user.posts.build(post_params)
    @post.posted_at = Time.current

    if @post.save
      redirect_to root_path, notice: "投稿しました"
    else
      render partial: "form", locals: { post: @post }, layout: false, status: :unprocessable_entity
    end
  end

  private

  def post_params
    params.require(:post).permit(:body, :mood, :visibility)
  end
end
