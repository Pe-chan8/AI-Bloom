require "rails_helper"

RSpec.describe User, type: :model do
  describe "association" do
    it "posts と関連している" do
      association = described_class.reflect_on_association(:posts)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end

    it "favorites と関連している" do
      association = described_class.reflect_on_association(:favorites)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end

    it "ai_messages と関連している" do
      association = described_class.reflect_on_association(:ai_messages)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end

    it "ai_message_feedbacks と関連している" do
      association = described_class.reflect_on_association(:ai_message_feedbacks)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end

    it "social_type_results と関連している" do
      association = described_class.reflect_on_association(:social_type_results)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end

    it "buddy に optional で belongs_to している" do
      association = described_class.reflect_on_association(:buddy)

      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:optional]).to eq(true)
    end
  end

  describe "validation" do
    let(:user) { build(:user) }

    it "nickname があれば有効" do
      user.nickname = "ぺーちゃん"

      expect(user).to be_valid
    end

    it "nickname がないと無効" do
      user.nickname = nil

      expect(user).not_to be_valid
      expect(user.errors[:nickname]).to be_present
    end

    it "nickname が31文字だと無効" do
      user.nickname = "a" * 31

      expect(user).not_to be_valid
      expect(user.errors[:nickname]).to be_present
    end

    it "social_type が定義内の値なら有効" do
      user.social_type = "expressive"

      expect(user).to be_valid
    end

    it "social_type が定義外の値だと無効" do
      user.social_type = "invalid_type"

      expect(user).not_to be_valid
      expect(user.errors[:social_type]).to be_present
    end

    it "recommended_buddy_type が定義内の値なら有効" do
      user.recommended_buddy_type = "amiable"

      expect(user).to be_valid
    end

    it "recommended_buddy_type が定義外の値だと無効" do
      user.recommended_buddy_type = "invalid_type"

      expect(user).not_to be_valid
      expect(user.errors[:recommended_buddy_type]).to be_present
    end

    it "dominant_type が定義内の値なら有効" do
      user.dominant_type = "analytical"

      expect(user).to be_valid
    end

    it "dominant_type が定義外の値だと無効" do
      user.dominant_type = "invalid_type"

      expect(user).not_to be_valid
      expect(user.errors[:dominant_type]).to be_present
    end
  end

  describe "#current_buddy" do
    let!(:normal_buddy) do
      Buddy.find_or_create_by!(code: "normal") do |buddy|
        buddy.name = "ニル"
        buddy.is_active = true
      end
    end

    context "buddyが設定されている場合" do
      let(:buddy) do
        Buddy.find_or_create_by!(code: "amiable") do |b|
          b.name = "ルナ"
          b.is_active = true
        end
      end
      let(:user) { create(:user, buddy: buddy) }

      it "設定されているbuddyを返す" do
        expect(user.current_buddy).to eq(buddy)
      end
    end

    context "buddyが設定されていない場合" do
      let(:user) { create(:user, buddy: nil) }

      it "code が normal の Buddy を返す" do
        expect(user.current_buddy).to eq(normal_buddy)
      end
    end
  end

  describe "#onboarded?" do
    it "onboarded_at がある場合は true を返す" do
      user = build(:user, onboarded_at: Time.zone.now)

      expect(user.onboarded?).to be true
    end

    it "onboarded_at がない場合は false を返す" do
      user = build(:user, onboarded_at: nil)

      expect(user.onboarded?).to be false
    end
  end
end
