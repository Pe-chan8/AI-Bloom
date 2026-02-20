# frozen_string_literal: true

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

      # ---- 非同期：AI返信生成（ここでは待たない）----
      @placeholder_id = build_placeholder_id

      # ポーリング開始時刻を記録（この時刻以降に生成されたAiMessageがあればcompleted）
      session[:ai_polling_started_at] ||= {}
      session[:ai_polling_started_at][@post.id.to_s] = Time.zone.now.iso8601

      Ai::GenerateBuddyReplyJob.perform_later(
        post_id: @post.id,
        user_id: current_user.id,
        buddy_id: @post.buddy_id,
        placeholder_id: @placeholder_id
      )

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

            # append は messages_list に統一
            turbo_stream.append(
              "messages_list",
              partial: "buddy_talks/system_notice",
              locals: { text: "よし、ここから一緒にやさしく振り返ろう🐧" }
            ),
            turbo_stream.append(
              "messages_list",
              partial: "buddy_talks/pending_ai",
              locals: { placeholder_id: @placeholder_id }
            ),

            turbo_stream.append(
              "ga-tracker",
              "<div data-controller=\"ga-event\" data-ga-event-name-value=\"buddy_talk_created\"></div>".html_safe
            )
          ]
        end

        # start は redirect で topic に飛ぶため、topic側で pending 表示を出せるよう created=1 を付ける
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

    # created=1 の初回表示で「まだAI返信が無い」なら pending を表示するフラグを立てる
    if params[:created].present?
      has_ai = @messages.any? { |m| m.is_a?(AiMessage) }
      @show_initial_pending = !has_ai
    end

    render :show
  end

  def reply
    text = params[:message].to_s.strip
    return redirect_to buddy_talk_topic_path(@buddy_talk) if text.blank?

    BuddyMessage.create!(user: current_user, post: @buddy_talk, role: :user, content: text) if defined?(BuddyMessage)

    buddy = @buddy_talk.buddy || current_buddy_fallback

    # ---- 非同期：AI返信生成（ここでは待たない）----
    @placeholder_id = build_placeholder_id

    # ポーリング開始時刻を記録（この時刻以降に生成されたAiMessageがあればcompleted）
    session[:ai_polling_started_at] ||= {}
    session[:ai_polling_started_at][@buddy_talk.id.to_s] = Time.zone.now.iso8601

    Ai::GenerateBuddyReplyJob.perform_later(
      post_id: @buddy_talk.id,
      user_id: current_user.id,
      buddy_id: buddy.id,
      placeholder_id: @placeholder_id
    )

    rerender_messages_and_composer(
      notice_text: "送信できたよ。バディが返事を考えてる…🐧💭",
      placeholder_id: @placeholder_id
    )
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

    @placeholder_id = build_placeholder_id

    # ポーリング開始時刻を記録
    session[:ai_polling_started_at] ||= {}
    session[:ai_polling_started_at][@buddy_talk.id.to_s] = Time.zone.now.iso8601

    Ai::GenerateDeepDiveJob.perform_later(
      post_id: @buddy_talk.id,
      user_id: current_user.id,
      buddy_id: buddy.id,
      placeholder_id: @placeholder_id
    )

    rerender_messages_and_composer(
      notice_text: "いいね。もう少しだけ一緒に深掘りしよう🐧",
      placeholder_id: @placeholder_id
    )
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

    @placeholder_id = build_placeholder_id

    # ポーリング開始時刻を記録
    session[:ai_polling_started_at] ||= {}
    session[:ai_polling_started_at][@buddy_talk.id.to_s] = Time.zone.now.iso8601

    Ai::GeneratePraiseSummaryJob.perform_later(
      post_id: @buddy_talk.id,
      user_id: current_user.id,
      buddy_id: buddy.id,
      placeholder_id: @placeholder_id
    )

    rerender_messages_and_composer(
      notice_text: "うん、やさしくまとめるね🐧🫶",
      placeholder_id: @placeholder_id
    )
  end

  def summary
    buddy = @buddy_talk.buddy || current_buddy_fallback

    @placeholder_id = build_placeholder_id

    # ポーリング開始時刻を記録
    session[:ai_polling_started_at] ||= {}
    session[:ai_polling_started_at][@buddy_talk.id.to_s] = Time.zone.now.iso8601

    Ai::GenerateSelfPrSummaryJob.perform_later(
      post_id: @buddy_talk.id,
      user_id: current_user.id,
      buddy_id: buddy.id,
      placeholder_id: @placeholder_id
    )

    rerender_messages_and_composer(
      notice_text: "振り返りを“言葉”に整えるね🐧✨",
      placeholder_id: @placeholder_id
    )
  end

  def restart
    session.delete(:buddy_talk_post_id)
    redirect_to buddy_talk_path(created: 1)
  end

  def close
    session.delete(:buddy_talk_post_id)
    redirect_to posts_path
  end

  # ポーリング用：AI生成完了確認
  def ai_status
    post = current_user.posts.find(params[:id])

    # ポーリング開始時刻（なければ post更新時刻を基準にする）
    started_at =
      begin
        t = session.dig(:ai_polling_started_at, post.id.to_s)
        t.present? ? Time.zone.parse(t) : nil
      rescue
        nil
      end

    started_at ||= post.updated_at || post.created_at

    # 「開始時刻以降」に生成されたAIメッセージがあるかで判定
    ai_completed = AiMessage.where(post: post).where("created_at >= ?", started_at).exists?

    render json: { completed: ai_completed }
  end

  private

  def rerender_messages_and_composer(notice_text:, placeholder_id:)
    @messages = build_timeline(@buddy_talk)
    buddy = @buddy_talk.buddy || current_buddy_fallback

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            "messages",
            partial: "buddy_talks/messages",
            locals: { messages: @messages, buddy: buddy, buddy_talk: @buddy_talk }
          ),

          # append は messages_list に統一
          turbo_stream.append(
            "messages_list",
            partial: "buddy_talks/system_notice",
            locals: { text: notice_text }
          ),
          turbo_stream.append(
            "messages_list",
            partial: "buddy_talks/pending_ai",
            locals: { placeholder_id: placeholder_id }
          ),

          turbo_stream.replace(
            "buddy_composer",
            partial: "buddy_talks/composer",
            locals: { buddy_talk: @buddy_talk }
          ),

          turbo_stream.append(
            "ga-tracker",
            "<div data-controller=\"ga-event\" data-ga-event-name-value=\"buddy_message_sent\"></div>".html_safe
          )
        ]
      end
      format.html { redirect_to buddy_talk_topic_path(@buddy_talk) }
    end
  end

  def build_placeholder_id
    "ai_pending_#{SecureRandom.hex(8)}"
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
