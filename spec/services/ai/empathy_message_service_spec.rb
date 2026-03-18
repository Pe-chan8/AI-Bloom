require "rails_helper"

RSpec.describe Ai::EmpathyMessageService, type: :service do
  let(:buddy) do
    create(
      :buddy,
      name: "ニル",
      persona_prompt: "やさしく寄り添って話してください"
    )
  end

  let(:user) { create(:user, nickname: "ぺーちゃん") }

  let(:post) do
    create(
      :post,
      user: user,
      buddy: buddy,
      body: "今日は少し疲れたけど頑張った",
      posted_at: Time.zone.now,
      category: "仕事"
    )
  end

  let(:client) { instance_double(OpenAI::Client) }

  let(:api_response) do
    {
      "choices" => [
        {
          "message" => {
            "content" => "  今日もよく頑張ったね。無理しすぎないでね。  "
          }
        }
      ],
      "usage" => {
        "prompt_tokens" => 100,
        "completion_tokens" => 20,
        "total_tokens" => 120
      }
    }
  end

  describe "#generate_for" do
    subject(:service_call) do
      described_class.new(client: client).generate_for(
        post: post,
        user: user,
        buddy: target_buddy
      )
    end

    let(:target_buddy) { buddy }

    before do
      allow(user).to receive(:buddy).and_return(buddy)

      create(:buddy_message, post: post, user: user, role: :user, content: "今日は会議が多くて疲れた")
      create(:buddy_message, post: post, user: user, role: :ai, content: "それは大変だったね")

      allow(client).to receive(:chat).and_return(api_response)
    end

    it "生成したメッセージをstripして返す" do
      expect(service_call).to eq("今日もよく頑張ったね。無理しすぎないでね。")
    end

    it "AiMessageをreply種別で保存する" do
      expect { service_call }.to change(AiMessage, :count).by(1)

      ai_message = AiMessage.last
      expect(ai_message.user).to eq(user)
      expect(ai_message.post).to eq(post)
      expect(ai_message.buddy).to eq(buddy)
      expect(ai_message.kind).to eq("reply")
      expect(ai_message.content).to eq("今日もよく頑張ったね。無理しすぎないでね。")
    end

    it "AiLogをsuccessで保存する" do
      expect { service_call }.to change(AiLog, :count).by(1)

      ai_log = AiLog.last
      expect(ai_log.user).to eq(user)
      expect(ai_log.post).to eq(post)
      expect(ai_log.ai_message).to eq(AiMessage.last)
      expect(ai_log.provider).to eq("openai")
      expect(ai_log.model).to eq(described_class::MODEL)
      expect(ai_log.prompt_tokens).to eq(100)
      expect(ai_log.completion_tokens).to eq(20)
      expect(ai_log.total_tokens).to eq(120)
      expect(ai_log.status).to eq("success")
      expect(ai_log.requested_at).to be_present
      expect(ai_log.responded_at).to be_present
    end

    it "OpenAI clientに期待したparametersでchatを呼ぶ" do
      service_call

      expect(client).to have_received(:chat) do |args|
        params = args[:parameters]

        expect(params[:model]).to eq(described_class::MODEL)
        expect(params[:temperature]).to eq(described_class::TEMPERATURE)
        expect(params[:max_tokens]).to eq(described_class::MAX_TOKENS)
        expect(params[:messages]).to be_an(Array)
        expect(params[:messages].map { |m| m[:role] }).to include("system", "user")
      end
    end

    context "buddyがnilで渡されたとき" do
      let(:target_buddy) { nil }

      it "user.buddyを使って保存する" do
        service_call

        expect(AiMessage.last.buddy).to eq(buddy)
      end
    end

    context "OpenAI呼び出しで例外が発生したとき" do
      before do
        allow(client).to receive(:chat).and_raise(StandardError, "API error")
      end

      it "フォールバック文言を返す" do
        expect(service_call).to eq("いま少し混み合っています…少し時間をおいてみてね🙏")
      end

      it "AiMessageを保存しない" do
        expect { service_call }.not_to change(AiMessage, :count)
      end

      it "AiLogを保存しない" do
        expect { service_call }.not_to change(AiLog, :count)
      end
    end
  end
end
