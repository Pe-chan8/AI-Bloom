# frozen_string_literal: true

module BuddyTalks
  class EnqueueService
    Result = Struct.new(:placeholder_id, keyword_init: true)

    def initialize(user:, post:, buddy:, session:)
      @user = user
      @post = post
      @buddy = buddy
      @session = session
    end

    def enqueue_reply!(message_text:)
      create_user_message!(message_text)

      placeholder_id = prepare_polling!

      Ai::GenerateBuddyReplyJob.perform_later(
        post_id: @post.id,
        user_id: @user.id,
        buddy_id: @buddy.id,
        placeholder_id: placeholder_id
      )

      Result.new(placeholder_id: placeholder_id)
    end

    def enqueue_deep_dive!
      create_user_message!("（バディと一緒に、もう少し振り返りたい）")

      placeholder_id = prepare_polling!

      Ai::GenerateDeepDiveJob.perform_later(
        post_id: @post.id,
        user_id: @user.id,
        buddy_id: @buddy.id,
        placeholder_id: placeholder_id
      )

      Result.new(placeholder_id: placeholder_id)
    end

    def enqueue_praise_summary!
      create_user_message!("（この会話を、やさしくまとめてほしい）")

      placeholder_id = prepare_polling!

      Ai::GeneratePraiseSummaryJob.perform_later(
        post_id: @post.id,
        user_id: @user.id,
        buddy_id: @buddy.id,
        placeholder_id: placeholder_id
      )

      Result.new(placeholder_id: placeholder_id)
    end

    def enqueue_summary!
      placeholder_id = prepare_polling!

      Ai::GenerateSelfPrSummaryJob.perform_later(
        post_id: @post.id,
        user_id: @user.id,
        buddy_id: @buddy.id,
        placeholder_id: placeholder_id
      )

      Result.new(placeholder_id: placeholder_id)
    end

    private

    def create_user_message!(text)
      return unless defined?(BuddyMessage)

      BuddyMessage.create!(
        user: @user,
        post: @post,
        role: :user,
        content: text
      )
    end

    def prepare_polling!
      placeholder_id = "ai_pending_#{SecureRandom.hex(8)}"

      @session[:ai_polling_started_at] ||= {}
      @session[:ai_polling_started_at][@post.id.to_s] = Time.zone.now.iso8601

      placeholder_id
    end
  end
end
