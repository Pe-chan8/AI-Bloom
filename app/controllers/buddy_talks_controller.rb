class BuddyTalksController < ApplicationController
  before_action :set_bottom_nav
  before_action :set_current_buddy_talk, only: [:show, :reply, :deep_dive, :summary]

  def show
    @post ||= Post.new(posted_at: Time.zone.now)
    @messages = build_timeline(@buddy_talk) if @buddy_talk.present?
  end

  # メタ + 初回本文で会話開始（= Post作成 + ユーザーメッセージ保存 + AI返信生成）
  def start
    @post = current_user.posts.new(post_params)

    tags = Array(params.dig(:post, :tag_list)).reject(&:blank?)
    @post.tags_text = tags.join(",") if @post.respond_to?(:tags_text=)

    if @post.save
      session[:buddy_talk_post_id] = @post.id

      first_text = @post.body.to_s.strip
      BuddyMessage.create!(user: current_user, post: @post, role: :user, content: first_text) if first_text.present?

      # EmpathyMessageService が AiMessage を保存するので、Controllerでは保存しない
      Ai::EmpathyMessageService.new.generate_for(post: @post, user: current_user, buddy: current_user.buddy)

      @buddy_talk = @post
      @messages = build_timeline(@buddy_talk)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("buddy_meta",
              partial: "buddy_talks/meta_readonly",
              locals: { buddy_talk: @buddy_talk }
            ),
            turbo_stream.replace("buddy_chat",
              partial: "buddy_talks/chat",
              locals: { buddy_talk: @buddy_talk, messages: @messages }
            ),
            turbo_stream.replace("buddy_composer",
              partial: "buddy_talks/composer",
              locals: { buddy_talk: @buddy_talk }
            )
          ]
        end
        format.html { redirect_to buddy_talk_path }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("buddy_meta",
            partial: "buddy_talks/meta_form",
            locals: { post: @post }
          )
        end
        format.html { render :show, status: :unprocessable_entity }
      end
    end
  end

  # チャット送信（ユーザー追記 → AI返信）
  def reply
    return redirect_to buddy_talk_path unless @buddy_talk

    text = params[:message].to_s.strip
    return redirect_to buddy_talk_path if text.blank?

    BuddyMessage.create!(user: current_user, post: @buddy_talk, role: :user, content: text)

    # 保存はService側
    Ai::EmpathyMessageService.new.generate_for(post: @buddy_talk, user: current_user, buddy: current_user.buddy)

    @messages = build_timeline(@buddy_talk)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("messages",
          partial: "buddy_talks/messages",
          locals: { messages: @messages }
        )
      end
      format.html { redirect_to buddy_talk_path }
    end
  end

  # 深掘り質問（AIから質問を追加）
  def deep_dive
    return redirect_to buddy_talk_path unless @buddy_talk

    Ai::DeepDiveQuestionService.new.generate_for(post: @buddy_talk, user: current_user, buddy: current_user.buddy)
    @messages = build_timeline(@buddy_talk)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("messages",
          partial: "buddy_talks/messages",
          locals: { messages: @messages }
        )
      end
      format.html { redirect_to buddy_talk_path }
    end
  end

  # 強みまとめ（AIで自己PR/強みを追加）
  def summary
    return redirect_to buddy_talk_path unless @buddy_talk

    Ai::SelfPrSummaryService.new.generate_for(post: @buddy_talk, user: current_user, buddy: current_user.buddy)
    @messages = build_timeline(@buddy_talk)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("messages",
          partial: "buddy_talks/messages",
          locals: { messages: @messages }
        )
      end
      format.html { redirect_to buddy_talk_path }
    end
  end

  # いったん「会話を閉じる」（一覧へ）
  def close
    session.delete(:buddy_talk_post_id)
    redirect_to posts_path, notice: "チャットを閉じました。"
  end

  private

  def set_bottom_nav
    @bottom_nav_key = "buddy_talk"
  end

  def set_current_buddy_talk
    id = session[:buddy_talk_post_id]
    @buddy_talk = current_user.posts.find_by(id: id) if id.present?
  end

  def post_params
    params.require(:post).permit(:posted_at, :title, :mood, :body)
  end

  def build_timeline(post)
    list = []
    list += BuddyMessage.where(post: post).order(:created_at).to_a
    list += AiMessage.where(post: post, kind: [:reply, :tip]).order(:created_at).to_a
    list.sort_by(&:created_at)
  end
end
