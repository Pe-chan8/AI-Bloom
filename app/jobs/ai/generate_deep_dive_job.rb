# frozen_string_literal: true

module Ai
  class GenerateDeepDiveJob < ApplicationJob
    queue_as :default

    def perform(post_id:, user_id:, buddy_id:, placeholder_id:)
      post = Post.find(post_id)
      user = User.find(user_id)
      buddy = Buddy.find(buddy_id)

      Ai::DeepDiveQuestionService.new.generate_for(post: post, user: user, buddy: buddy)

      Turbo::StreamsChannel.broadcast_remove_to("buddy_talks:#{post.id}", target: placeholder_id)

      ai_message =
        AiMessage
          .where(post: post, buddy_id: buddy.id)
          .includes(:buddy)
          .order(:created_at)
          .last

      return if ai_message.nil?

      Turbo::StreamsChannel.broadcast_append_to(
        "buddy_talks:#{post.id}",
        target: "messages_list",
        partial: "buddy_talks/message",
        locals: { message: ai_message, buddy: ai_message.buddy }
      )
    rescue => e
      Rails.logger.error("[GenerateDeepDiveJob] #{e.class} #{e.message}")
      Turbo::StreamsChannel.broadcast_remove_to("buddy_talks:#{post_id}", target: placeholder_id)
    end
  end
end
