class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, only: %i[edit update destroy]
  before_action :authorize_post!, only: %i[edit update destroy]

  # 一覧表示（自分の投稿のみ）
  def index
    # 検索キーワード（nil 回避して trim）
    @query = params[:q].to_s.strip

    base_scope =
      current_user.posts
                  .order(posted_at: :desc)

    # 検索ワードがあれば body をあいまい検索
    @posts =
      if @query.present?
        base_scope.where("body ILIKE ?", "%#{@query}%")
      else
        base_scope
      end

    # ページネーション（1ページ10件）
    @posts = @posts.page(params[:page]).per(10)
  end

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
    # @post は before_action でセット＆権限チェック済み
  end

  def update
    if @post.update(post_params)
      redirect_to root_path, notice: "投稿を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # 投稿削除
  def destroy
    @post.destroy!
    redirect_to posts_path, notice: "投稿を削除しました"
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  # 自分の投稿以外は編集・削除させないようにする
  def authorize_post!
    redirect_to root_path, alert: "この投稿は編集できません" if @post.user_id != current_user.id
  end

  def post_params
    params.require(:post).permit(:body, :mood, :visibility)
  end
end
