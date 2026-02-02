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

  # もうモーダル運用しないなら new は不要だけど、残してもOK
  def new
    @post = Post.new
  end

  def create
    @post = current_user.posts.build(post_params)

    # posted_at 未入力対策（念のため）
    @post.posted_at ||= Time.zone.now

    # tag_list(チェックボックス) → tags_text(保存) に詰める
    @post.tags_text = Array(params.dig(:post, :tag_list)).join(", ")

    if @post.save
      begin
        buddy   = current_user.buddy
        service = Ai::EmpathyMessageService.new
        service.generate_for(post: @post, user: current_user, buddy: buddy)
      rescue => e
        Rails.logger.error "[AI] create時のメッセージ生成に失敗: #{e.class} #{e.message}"
      end

      current_user.update!(onboarded_at: Time.current) unless current_user.onboarded?

      redirect_to post_path(@post), notice: "投稿が完了しました！"
    else
      # BuddyTalk の入力画面に戻す（render だと変数不足で落ちやすいので redirect 推奨）
      redirect_to buddy_talk_path, alert: @post.errors.full_messages.to_sentence
    end
  end

  def edit; end

  def update
    @post.tags_text = Array(params.dig(:post, :tag_list)).join(", ")

    if @post.update(post_params)
      redirect_to post_path(@post), notice: "投稿を更新しました"
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
    params.require(:post).permit(:body, :mood, :visibility, :posted_at, :title, :tags_text)
  end

  def set_bottom_nav
    @bottom_nav_key = "posts"
  end
end
