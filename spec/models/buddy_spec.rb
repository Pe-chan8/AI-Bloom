require "rails_helper"

RSpec.describe Buddy, type: :model do
  describe "association" do
    it "posts と関連している" do
      association = described_class.reflect_on_association(:posts)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:nullify)
    end

    it "ai_messages と関連している" do
      association = described_class.reflect_on_association(:ai_messages)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:nullify)
    end
  end

  describe "validation" do
    subject(:buddy) { build(:buddy) }

    it "code と name があれば有効" do
      expect(buddy).to be_valid
    end

    it "code がないと無効" do
      buddy.code = nil

      expect(buddy).not_to be_valid
      expect(buddy.errors[:code]).to be_present
    end

    it "name がないと無効" do
      buddy.name = nil

      expect(buddy).not_to be_valid
      expect(buddy.errors[:name]).to be_present
    end

    it "code が重複すると無効" do
      create(:buddy, code: "unique_code")
      duplicate_buddy = build(:buddy, code: "unique_code")

      expect(duplicate_buddy).not_to be_valid
      expect(duplicate_buddy.errors[:code]).to be_present
    end
  end

  describe ".active" do
    let!(:active_buddy) { create(:buddy, code: "active_code", is_active: true) }
    let!(:inactive_buddy) { create(:buddy, code: "inactive_code", is_active: false) }

    it "is_active が true の buddy のみ返す" do
      expect(Buddy.active).to include(active_buddy)
      expect(Buddy.active).not_to include(inactive_buddy)
    end
  end

  describe "#display_name" do
    it "code に対応する表示名がある場合は対応名を返す" do
      buddy = build(:buddy, code: "amiable", name: "テスト名")

      expect(buddy.display_name).to eq("ルナ")
    end

    it "code に対応する表示名がない場合は name を返す" do
      buddy = build(:buddy, code: "unknown", name: "テスト名")

      expect(buddy.display_name).to eq("テスト名")
    end
  end

  describe "#avatar_image_path" do
    it "code に対応する画像がある場合はその画像パスを返す" do
      buddy = build(:buddy, code: "normal")

      expect(buddy.avatar_image_path).to eq("buddies/normal_buddy.png")
    end

    it "code に対応する画像がない場合はデフォルト画像を返す" do
      buddy = build(:buddy, code: "unknown")

      expect(buddy.avatar_image_path).to eq("buddies/normal_buddy.png")
    end
  end
end
