require "rails_helper"

RSpec.describe Ai::GenerateDeepDiveJob, type: :job do
  describe "#perform" do
    let(:user) { create(:user) }
    let(:buddy) { create(:buddy) }
    let(:post_record) { create(:post, user: user) }
    let(:placeholder_id) { "loading-message-1" }

    before do
      allow(Turbo::StreamsChannel).to receive(:broadcast_remove_to)
      allow(Turbo::StreamsChannel).to receive(:broadcast_append_to)
    end

    it "DeepDiveQuestionServiceを呼び出し、生成されたAIメッセージをbroadcastする" do
      service = instance_double(Ai::DeepDiveQuestionService)

      allow(Ai::DeepDiveQuestionService).to receive(:new).and_return(service)
      allow(service).to receive(:generate_for) do
        create(
          :ai_message,
          user: user,
          buddy: buddy,
          post: post_record,
          kind: :reply,
          content: "深掘りメッセージ"
        )
      end

      described_class.perform_now(
        post_id: post_record.id,
        user_id: user.id,
        buddy_id: buddy.id,
        placeholder_id: placeholder_id
      )

      expect(service).to have_received(:generate_for).with(
        post: post_record,
        user: user,
        buddy: buddy
      )

      expect(Turbo::StreamsChannel).to have_received(:broadcast_remove_to).with(
        "buddy_talks:#{post_record.id}",
        target: placeholder_id
      )

      ai_message = AiMessage.where(post: post_record, buddy: buddy).order(created_at: :desc).first

      expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to).with(
        "buddy_talks:#{post_record.id}",
        target: "messages_list",
        partial: "buddy_talks/message",
        locals: { message: ai_message, buddy: buddy }
      )
    end

    it "AIメッセージが生成されなかった場合はフォールバック文言のメッセージを作成してbroadcastする" do
      service = instance_double(Ai::DeepDiveQuestionService)

      allow(Ai::DeepDiveQuestionService).to receive(:new).and_return(service)
      allow(service).to receive(:generate_for)

      expect do
        described_class.perform_now(
          post_id: post_record.id,
          user_id: user.id,
          buddy_id: buddy.id,
          placeholder_id: placeholder_id
        )
      end.to change(AiMessage, :count).by(1)

      ai_message = AiMessage.order(created_at: :desc).first

      expect(ai_message.user).to eq(user)
      expect(ai_message.buddy).to eq(buddy)
      expect(ai_message.post).to eq(post_record)
      expect(ai_message.kind).to eq("reply")
      expect(ai_message.content).to eq("ごめんね、いまうまく作れなかった…🙏 もう一度押してみてね。")

      expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to).with(
        "buddy_talks:#{post_record.id}",
        target: "messages_list",
        partial: "buddy_talks/message",
        locals: { message: ai_message, buddy: buddy }
      )
    end

    it "例外発生時はログ出力とplaceholder削除を行って再raiseする" do
      service = instance_double(Ai::DeepDiveQuestionService)
      error = StandardError.new("test error")

      allow(Ai::DeepDiveQuestionService).to receive(:new).and_return(service)
      allow(service).to receive(:generate_for).and_raise(error)
      allow(Rails.logger).to receive(:error)

      expect do
        described_class.perform_now(
          post_id: post_record.id,
          user_id: user.id,
          buddy_id: buddy.id,
          placeholder_id: placeholder_id
        )
      end.to raise_error(StandardError, "test error")

      expect(Rails.logger).to have_received(:error).with("[GenerateDeepDiveJob] StandardError test error")
      expect(Turbo::StreamsChannel).to have_received(:broadcast_remove_to).with(
        "buddy_talks:#{post_record.id}",
        target: placeholder_id
      )
    end
  end
end
