class BuddyTalksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_bottom_nav

  # show: sessionに紐づく「今の会話」
  before_action :set_current_buddy_talk, only: [:show]

  # topic/reply/deep_dive/summary/close: URLの :id で取る
  before_action :set_topic_buddy_talk, only: [:topic, :reply, :deep_dive, :summary, :close]

  # 新規会話（未開始ならフォーム、開始済みなら会話ログ）
  def show
    @post ||= Post.new(posted_at: Time.zone.now)
    @messages = build_timeline(@buddy_talk) if @buddy_talk.present?
  end

  # メタ + 初回本文で会話開始（= Post作成 + 初回AI返信生成）
  def start
    @post = current_user.posts.new(post_params)

    # tags（post[tag_list][]=...）→ tags_text に寄せる
    tags = Array(params.dig(:post, :tag_list)).reject(&:blank?)
    @post.tags_text = tags.join(",") if @post.respond_to?(:tags_text=)

    if @post.save
      # 今の会話トピックとして保存
      session[:buddy_talk_post_id] = @post.id

      # 初回ユーザー文を BuddyMessage へ（存在する場合のみ）
      first_text = @post.body.to_s.strip
      if first_text.present? && defined?(BuddyMessage)
        BuddyMessage.create!(user: current_user, post: @post, role: :user, content: first_text)
      end

      # AI受容返信：ここでは「1回だけ」呼ぶ（サービス内で AiMessage を作成する想定）
      Ai::EmpathyMessageService.new.generate_for(post: @post, user: current_user, buddy: current_user.buddy)

      @buddy_talk = @post
      @messages = build_timeline(@buddy_talk)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "buddy_meta",
              partial: "buddy_talks/meta_readonly",
              locals: { buddy_talk: @buddy_talk }
            ),
            turbo_stream.replace(
              "buddy_chat",
              partial: "buddy_talks/chat",
              locals: { buddy_talk: @buddy_talk, messages: @messages }
            ),
            turbo_stream.replace(
              "buddy_composer",
              partial: "buddy_talks/composer",
              locals: { buddy_talk: @buddy_talk }
            )
          ]
        end
        format.html { redirect_to buddy_talk_topic_path(@buddy_talk) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "buddy_meta",
            partial: "buddy_talks/meta_form",
            locals: { post: @post }
          )
        end
        format.html { render :show, status: :unprocessable_entity }
      end
    end
  end

  # トピック別会話（一覧→特定トピックへ）
  def topic
    session[:buddy_talk_post_id] = @buddy_talk.id
    @messages = build_timeline(@buddy_talk)
    render :show
  end

  # チャット送信（ユーザー→受容返信）
  def reply
    text = params[:message].to_s.strip
    if text.blank?
      return redirect_to buddy_talk_topic_path(@buddy_talk)
    end

    if defined?(BuddyMessage)
      BuddyMessage.create!(user: current_user, post: @buddy_talk, role: :user, content: text)
    end

    # AI受容返信：ここも「1回だけ」
    Ai::EmpathyMessageService.new.generate_for(post: @buddy_talk, user: current_user, buddy: current_user.buddy)

    @messages = build_timeline(@buddy_talk)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "messages",
          partial: "buddy_talks/messages",
          locals: { messages: @messages }
        )
      end
      format.html { redirect_to buddy_talk_topic_path(@buddy_talk) }
    end
  end

  # 深掘り質問（AIだけ）
  def deep_dive
    Ai::DeepDiveQuestionService.new.generate_for(post: @buddy_talk, user: current_user, buddy: current_user.buddy)

    @messages = build_timeline(@buddy_talk)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "messages",
          partial: "buddy_talks/messages",
          locals: { messages: @messages }
        )
      end
      format.html { redirect_to buddy_talk_topic_path(@buddy_talk) }
    end
  end

  # 強みまとめ（自己PR）
  def summary
    Ai::SelfPrSummaryService.new.generate_for(post: @buddy_talk, user: current_user, buddy: current_user.buddy)

    @messages = build_timeline(@buddy_talk)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "messages",
          partial: "buddy_talks/messages",
          locals: { messages: @messages }
        )
      end
      format.html { redirect_to buddy_talk_topic_path(@buddy_talk) }
    end
  end

  # 閉じる（sessionを切って一覧へ）
  def close
    session.delete(:buddy_talk_post_id)
    redirect_to posts_path
  end

  private

  def set_bottom_nav
    @bottom_nav_key = "buddy_talk"
  end

  # show用（sessionに紐づく「今の会話」）
  def set_current_buddy_talk
    id = session[:buddy_talk_post_id]
    @buddy_talk = current_user.posts.find_by(id: id) if id.present?
  end

  # topic/reply/deep_dive/summary/close 用（URLの :id から取る）
  def set_topic_buddy_talk
    @buddy_talk = current_user.posts.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:posted_at, :title, :mood, :body)
  end

  # ユーザー発言（BuddyMessage）＋AI返信（AiMessage）を時系列で混ぜる
  def build_timeline(post)
    list = []

    if defined?(BuddyMessage)
      list += BuddyMessage.where(post: post).order(:created_at).to_a
    end

    list += AiMessage.where(post: post, kind: [:reply, :tip]).order(:created_at).to_a

    list.sort_by(&:created_at)
  end
end
