# frozen_string_literal: true

module Ai
  class GenerateEmpathyReplyJob < ApplicationJob
    queue_as :default

    def perform(post_id:, user_id:, buddy_id:, placeholder_id:)
      Ai::GenerateBuddyReplyJob.perform_now(
        post_id: post_id,
        user_id: user_id,
        buddy_id: buddy_id,
        placeholder_id: placeholder_id
      )
    end
  end
end
