module Ai
  class ConversationContext
    def initialize(post:)
      @post = post
    end

    def messages(limit: 30)
      timeline = []
      timeline += BuddyMessage.where(post: @post).order(:created_at).to_a
      timeline += AiMessage.where(post: @post).order(:created_at).to_a
      timeline.sort_by!(&:created_at)

      timeline.last(limit).map do |m|
        if m.is_a?(BuddyMessage)
          { role: "user", content: m.content.to_s }
        else
          # AiMessage: kindに関係なく「assistant」として積む
          { role: "assistant", content: m.content.to_s }
        end
      end
    end
  end
end
