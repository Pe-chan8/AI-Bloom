# frozen_string_literal: true

module Ai
  class GenerateBuddyReplyJob < ApplicationJob
    queue_as :default

    def perform(post_id:, user_id:, buddy_id:, placeholder_id:)
      post = Post.find(post_id)
      user = User.find(user_id)
      buddy = Buddy.find(buddy_id)

      # 1) AI返信（AiMessage）を生成（保存はService側）
      Ai::EmpathyMessageService.new.generate_for(post: post, user: user, buddy: buddy)

      # 2) 最新の reply を取得
      ai_message =
        AiMessage.where(post: post, buddy_id: buddy.id, kind: :reply)
                 .order(created_at: :desc)
                 .first

      # 3) ローディングを消す（先に必ず消す）
      Turbo::StreamsChannel.broadcast_remove_to(
        "buddy_talks:#{post.id}",
        target: placeholder_id
      )

      # 4) 返信が作れなかった場合のフォールバック（表示だけはする）
      unless ai_message
        ai_message = AiMessage.create!(
          user: user,
          buddy: buddy,
          post: post,
          kind: :reply,
          content: "ごめんね、いま少し混み合ってるみたい…🙏 もう一度送ってみてね。"
        )
      end

      # 5) メッセージ追加（messages_list に統一）
      Turbo::StreamsChannel.broadcast_append_to(
        "buddy_talks:#{post.id}",
        target: "messages_list",
        partial: "buddy_talks/message",
        locals: { message: ai_message, buddy: buddy }
      )
    rescue => e
      Rails.logger.error("[GenerateBuddyReplyJob] #{e.class} #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      Turbo::StreamsChannel.broadcast_remove_to(
        "buddy_talks:#{post_id}",
        target: placeholder_id
      )
      raise
    end
  end
end
