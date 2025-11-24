class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, only: %i[edit update]
  before_action :authorize_post!, only: %i[edit update]

  # モーダル用：新規投稿
  def new
    @post = Post.new
    render partial: "form", locals: { post: @post, mode: :modal }, layout: false
  end

  def create
    @post = current_user.posts.build(post_params)
    @post.posted_at = Time.current

    if @post.save
      redirect_to root_path, notice: "投稿しました"
    else
      # モーダル内でバリデーションエラーを表示したいので layout: false
      render partial: "form",
             locals: { post: @post, mode: :modal },
             layout: false,
             status: :unprocessable_entity
    end
  end

  # ページ遷移版：投稿編集画面
  def edit
    # @post は before_action でセット済み
  end

  def update
    if @post.update(post_params)
      redirect_to root_path, notice: "投稿を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  # 自分の投稿以外は編集させないようにする
  def authorize_post!
    redirect_to root_path, alert: "この投稿は編集できません" if @post.user_id != current_user.id
  end

  def post_params
    params.require(:post).permit(:body, :mood, :visibility)
  end
end
