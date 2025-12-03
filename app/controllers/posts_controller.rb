class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, only: %i[show edit update destroy]
  before_action :authorize_post!, only: %i[edit update destroy]
  before_action :set_bottom_nav

  # 一覧表示（検索 + ページネーション）
  def index
    base_scope = current_user.posts.order(posted_at: :desc)
    @q = base_scope.ransack(params[:q])
    @posts = @q.result(distinct: true).page(params[:page]).per(10)
  end

  # 投稿詳細：ここで自動的にAIメッセージを生成する
  def show
    @buddy = current_user.buddy

    # ① まずはこの投稿に紐づく最新の AiMessage を探す
    @ai_message = @post.ai_messages.reply.order(created_at: :desc).first

    # ② なければ生成して保存（service 内で create! 済み）
    if @ai_message.nil?
      service = Ai::EmpathyMessageService.new

      text = service.generate_for(
        post:  @post,
        user:  current_user,
        buddy: @buddy
      )

      # 直近のレコードを取り直す（万一に備えて）
      @ai_message = @post.ai_messages.reply.order(created_at: :desc).first ||
                    AiMessage.new(content: text, user: current_user, buddy: @buddy, post: @post, kind: :reply)
    end

    # ビューで使いやすいように文字列も用意しておく
    @ai_preview_message = @ai_message.content
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
      render partial: "form",
             locals: { post: @post, mode: :modal },
             layout: false,
             status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      redirect_to root_path, notice: "投稿を更新しました"
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
    params.require(:post).permit(:body, :mood, :visibility)
  end

  def set_bottom_nav
    @bottom_nav_key = "posts"
  end
end
