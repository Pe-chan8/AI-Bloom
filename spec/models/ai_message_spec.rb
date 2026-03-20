require "rails_helper"

RSpec.describe AiMessage, type: :model do
  describe "association" do
    it "user に belongs_to している" do
      association = described_class.reflect_on_association(:user)

      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:optional]).not_to eq(true)
    end

    it "post に optional で belongs_to している" do
      association = described_class.reflect_on_association(:post)

      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:optional]).to eq(true)
    end

    it "buddy に optional で belongs_to している" do
      association = described_class.reflect_on_association(:buddy)

      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:optional]).to eq(true)
    end

    it "ai_message_feedbacks と関連している" do
      association = described_class.reflect_on_association(:ai_message_feedbacks)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end

    it "ai_logs と関連している" do
      association = described_class.reflect_on_association(:ai_logs)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end
  end

  describe "enum" do
    it "kind の定義が正しい" do
      expect(described_class.kinds).to eq(
        "daily" => 0,
        "weekly" => 1,
        "reply" => 2,
        "tip" => 3,
        "analysis_feedback" => 4
      )
    end

    it "sentiment の定義が正しい" do
      expect(described_class.sentiments).to eq(
        "positive" => 0,
        "neutral" => 1,
        "negative" => 2
      )
    end
  end

  describe "default" do
    it "kind のデフォルトは reply" do
      ai_message = described_class.new

      expect(ai_message.kind).to eq("reply")
    end
  end
end
