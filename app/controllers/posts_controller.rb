class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, only: %i[show edit update destroy]
  before_action :authorize_post!, only: %i[edit update destroy]
  before_action :set_bottom_nav

  def index
    base_scope = current_user.posts.order(posted_at: :desc)
    @q = base_scope.ransack(params[:q])
    @posts = @q.result(distinct: true).page(params[:page]).per(10)
  end

  def show
    @buddy        = current_user.buddy
    @rate_limited = false

    @ai_message = @post.ai_messages.reply.order(created_at: :desc).first

    placeholder =
      @ai_message&.content.to_s.include?("混み合っています") ||
      @ai_message&.content.to_s.include?("少し時間をおいて")

    if @ai_message.nil? || placeholder
      begin
        service = Ai::EmpathyMessageService.new
        service.generate_for(post: @post, user: current_user, buddy: @buddy)
        @ai_message = @post.ai_messages.reply.order(created_at: :desc).first
      rescue Faraday::TooManyRequestsError, Ai::RateLimiter::LimitExceeded
        @rate_limited = true
      rescue => e
        Rails.logger.error "[AI] showでの生成失敗: #{e.class} #{e.message}"
        @rate_limited = true
      end
    end
  end

  def new
    @post = Post.new
    render :new, layout: false if turbo_frame_request?
  end

  def create
    @post = current_user.posts.build(post_params)
    @post.posted_at = Time.current

    if @post.save
      begin
        buddy   = current_user.buddy
        service = Ai::EmpathyMessageService.new
        service.generate_for(post: @post, user: current_user, buddy: buddy)
      rescue => e
        Rails.logger.error "[AI] create時のメッセージ生成に失敗: #{e.class} #{e.message}"
      end

      current_user.update!(onboarded_at: Time.current) unless current_user.onboarded?

      # ★ここが大事：フラッシュは「次の遷移」で出すために積む
      flash[:notice] = "投稿が完了しました！"

      respond_to do |format|
        # モーダル(Turbo)用：create.turbo_stream.erb を返す
        format.turbo_stream
        # 通常画面用：従来通りリダイレクト
        format.html { redirect_to post_path(@post) }
      end
    else
      if turbo_frame_request?
        render partial: "posts/form",
              locals: { post: @post, mode: :modal },
              layout: false,
              status: :unprocessable_entity
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  def edit; end

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
