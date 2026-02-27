require "rails_helper"

RSpec.describe Post, type: :model do
  let(:user) { create_user }

  def valid_category
    if Post.respond_to?(:categories) && Post.categories.is_a?(Hash) && Post.categories.any?
      Post.categories.keys.first
    else
      "general"
    end
  end

  it "必須項目が揃っていれば有効" do
    post = Post.new(
      user: user,
      body: "今日はがんばった",
      posted_at: Time.zone.now,
      title: "テスト",
      category: valid_category
    )

    expect(post).to be_valid
  end

  it "必須項目が欠けると無効（bodyなし）" do
    post = Post.new(
      user: user,
      body: nil,
      posted_at: Time.zone.now,
      title: "テスト",
      category: valid_category
    )

    expect(post).not_to be_valid
  end
end
