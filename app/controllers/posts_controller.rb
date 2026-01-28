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

  # 投稿詳細：AIメッセージ表示
  def show
    @buddy        = current_user.buddy
    @rate_limited = false

    # ① 最新の reply を取得
    @ai_message = @post.ai_messages.reply.order(created_at: :desc).first

    # ② 「混み合っています…」表示だったら再生成したい（ダミー判定）
    placeholder =
      @ai_message&.content.to_s.include?("混み合っています") ||
      @ai_message&.content.to_s.include?("少し時間をおいて")

    # ③ reply がない or ダミーなら生成
    if @ai_message.nil? || placeholder
      begin
        service = Ai::EmpathyMessageService.new
        text = service.generate_for(post: @post, user: current_user, buddy: @buddy)

        # generate_for 内で AiMessage.create! 済みなので取り直す
        @ai_message = @post.ai_messages.reply.order(created_at: :desc).first

      rescue Faraday::TooManyRequestsError, Ai::RateLimiter::LimitExceeded
        @rate_limited = true
      rescue => e
        Rails.logger.error "[AI] showでの生成失敗: #{e.class} #{e.message}"
        @rate_limited = true
      end
    end
  end

  # モーダル用：新規投稿
  def new
    @post = Post.new

    if turbo_frame_request?
      render :new, layout: false
      Rails.logger.debug "[posts#new] turbo_frame_request?=#{turbo_frame_request?}"
    end
  end

  def create
    @post = current_user.posts.build(post_params)
    @post.posted_at = Time.current

    if @post.save
      begin
        buddy   = current_user.buddy
        service = Ai::EmpathyMessageService.new
        text = service.generate_for(post: @post, user: current_user, buddy: buddy)

        @post.ai_messages.create!(
          user: current_user, buddy: buddy, kind: :reply, content: text
        )
      rescue => e
        Rails.logger.error "[AI] create時のメッセージ生成に失敗: #{e.class} #{e.message}"
      end

      # ▼ 初回の「何かした」扱いにする（オンボーディング完了）
      current_user.update!(onboarded_at: Time.current) unless current_user.onboarded?

      redirect_to post_path(@post), notice: "投稿しました"
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
