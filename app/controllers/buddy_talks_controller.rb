class BuddyTalksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_bottom_nav

  before_action :set_current_buddy_talk, only: [ :show ]
  before_action :set_topic_buddy_talk,   only: [ :topic, :reply, :deep_dive, :summary, :praise_summary, :close, :restart ]

  def show
    @post ||= Post.new(posted_at: Time.zone.now)
    return unless @buddy_talk.present?

    @messages = build_timeline(@buddy_talk)
    @buddy    = @buddy_talk.buddy || current_buddy_fallback
  end

  def start
    @post = current_user.posts.new(post_params)

    tags = Array(params.dig(:post, :tag_list)).reject(&:blank?)
    @post.tags_text = tags.join(",") if @post.respond_to?(:tags_text=)

    # この会話の返信担当バディを固定（1会話＝1バディ）
    @post.buddy = current_buddy_fallback

    if @post.save
      session[:buddy_talk_post_id] = @post.id

      first_text = @post.body.to_s.strip
      if first_text.present? && defined?(BuddyMessage)
        BuddyMessage.create!(user: current_user, post: @post, role: :user, content: first_text)
      end

      Ai::EmpathyMessageService.new.generate_for(post: @post, user: current_user, buddy: @post.buddy)

      @buddy_talk = @post
      @messages   = build_timeline(@buddy_talk)
      @buddy      = @buddy_talk.buddy || current_buddy_fallback

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
              locals: { buddy_talk: @buddy_talk, messages: @messages, buddy: @buddy }
            ),
            turbo_stream.replace(
              "buddy_composer",
              partial: "buddy_talks/composer",
              locals: { buddy_talk: @buddy_talk }
            ),
            turbo_stream.append(
              "ga-tracker",
              "<div data-controller=\"ga-event\" data-ga-event-name-value=\"buddy_talk_created\"></div>".html_safe
            )
          ]
        end
        format.html { redirect_to buddy_talk_topic_path(@buddy_talk, created: 1) }
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

  def topic
    session[:buddy_talk_post_id] = @buddy_talk.id
    @messages = build_timeline(@buddy_talk)
    @buddy    = @buddy_talk.buddy || current_buddy_fallback
    render :show
  end

  def reply
    text = params[:message].to_s.strip
    return redirect_to buddy_talk_topic_path(@buddy_talk) if text.blank?

    BuddyMessage.create!(user: current_user, post: @buddy_talk, role: :user, content: text) if defined?(BuddyMessage)

    buddy = @buddy_talk.buddy || current_buddy_fallback
    Ai::EmpathyMessageService.new.generate_for(post: @buddy_talk, user: current_user, buddy: buddy)

    rerender_messages_and_composer
  end

  def deep_dive
    if defined?(BuddyMessage)
      BuddyMessage.create!(
        user: current_user,
        post: @buddy_talk,
        role: :user,
        content: "（バディと一緒に、もう少し振り返りたい）"
      )
    end

    buddy = @buddy_talk.buddy || current_buddy_fallback
    Ai::DeepDiveQuestionService.new.generate_for(post: @buddy_talk, user: current_user, buddy: buddy)

    rerender_messages_and_composer
  end

  def praise_summary
    if defined?(BuddyMessage)
      BuddyMessage.create!(
        user: current_user,
        post: @buddy_talk,
        role: :user,
        content: "（この会話を、やさしくまとめてほしい）"
      )
    end

    buddy = @buddy_talk.buddy || current_buddy_fallback
    Ai::PraiseSummaryService.new.generate_for(post: @buddy_talk, user: current_user, buddy: buddy)

    rerender_messages_and_composer
  end

  def summary
    buddy = @buddy_talk.buddy || current_buddy_fallback
    Ai::SelfPrSummaryService.new.generate_for(post: @buddy_talk, user: current_user, buddy: buddy)
    rerender_messages_and_composer
  end

  def restart
    session.delete(:buddy_talk_post_id)
    redirect_to buddy_talk_path(created: 1)
  end

  def close
    session.delete(:buddy_talk_post_id)
    redirect_to posts_path
  end

  private

  def rerender_messages_and_composer
    @messages = build_timeline(@buddy_talk)
    buddy = @buddy_talk.buddy || current_buddy_fallback

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            "messages",
            partial: "buddy_talks/messages",
            locals: { messages: @messages, buddy: buddy }
          ),
          turbo_stream.replace(
            "buddy_composer",
            partial: "buddy_talks/composer",
            locals: { buddy_talk: @buddy_talk }
          ),
          turbo_stream.append(
            "ga-tracker",
            "<div data-controller=\"ga-event\" data-ga-event-name-value=\"buddy_message_sent\"></div>".html_safe
          ),
          turbo_stream.append(
            "ga-tracker",
            "<div data-controller=\"ga-event\" data-ga-event-name-value=\"ai_reply_generated\"></div>".html_safe
          )
        ]
      end
      format.html { redirect_to buddy_talk_topic_path(@buddy_talk) }
    end
  end

  def set_bottom_nav
    @bottom_nav_key = "buddy_talk"
  end

  def set_current_buddy_talk
    id = session[:buddy_talk_post_id]
    @buddy_talk = current_user.posts.find_by(id: id) if id.present?
  end

  def set_topic_buddy_talk
    @buddy_talk = current_user.posts.find(params[:id])
  end

  def post_params
    params.require(:post).permit(
      :posted_at, :title, :mood, :body,
      :category, :subcategory
    )
  end

  # “1会話＝1バディ” を守るため、timelineも会話担当buddyのAiMessageだけに絞る
  def build_timeline(post)
    list = []
    list += BuddyMessage.where(post: post).order(:created_at).to_a if defined?(BuddyMessage)

    ai_scope = AiMessage.where(post: post, kind: [ :reply, :tip, :weekly ])
    ai_scope = ai_scope.where(buddy_id: post.buddy_id) if post.buddy_id.present?
    list += ai_scope.order(:created_at).to_a

    list.sort_by(&:created_at)
  end

  def current_buddy_fallback
    current_user.buddy || Buddy.find_by(code: "normal")
  end
end
