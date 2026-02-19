# frozen_string_literal: true

module Ai
  class GenerateEmpathyReplyJob < ApplicationJob
    queue_as :default

    def perform(post_id:, user_id:, buddy_id:, placeholder_id:)
      post = Post.find(post_id)
      user = User.find(user_id)
      buddy = Buddy.find(buddy_id)

      content = Ai::EmpathyMessageService.new.generate_for(post: post, user: user, buddy: buddy)

      ai_message = AiMessage.where(post: post, buddy: buddy, kind: :reply).order(:created_at).last

      Turbo::StreamsChannel.broadcast_remove_to(
        "buddy_talks:#{post.id}",
        target: placeholder_id
      )

      Turbo::StreamsChannel.broadcast_append_to(
        "buddy_talks:#{post.id}",
        target: "messages",
        partial: "buddy_talks/message",
        locals: { message: ai_message }
      )
    rescue => e
      Turbo::StreamsChannel.broadcast_replace_to(
        "buddy_talks:#{post_id}",
        target: placeholder_id,
        html: "<div class='text-sm text-rose-600'>ごめんね、いま混み合ってるみたい…🙏（#{ERB::Util.h(e.class)}）</div>"
      )
      raise
    end
  end
end
