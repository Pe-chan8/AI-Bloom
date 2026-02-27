require "rails_helper"

RSpec.describe "BuddyTalks enqueue", type: :request do
  let(:user) { create_user(email: "t_enqueue2@example.com") }

  let!(:buddy) do
    Buddy.find_by(code: "normal") || Buddy.create!(code: "normal", name: "ノーマル")
  end

  def valid_category
    if Post.respond_to?(:categories) && Post.categories.is_a?(Hash) && Post.categories.any?
      Post.categories.keys.first
    else
      "general"
    end
  end

  let!(:buddy_talk) do
    user.posts.create!(
      body: "テスト投稿",
      posted_at: Time.zone.now,
      title: "テスト",
      category: valid_category,
      buddy: buddy
    )
  end

  before { sign_in user }

  it "reply で Ai::GenerateBuddyReplyJob が呼ばれる（perform_later）" do
    expect(Ai::GenerateBuddyReplyJob).to receive(:perform_later)

    post "/buddy_talks/#{buddy_talk.id}/reply", params: { message: "こんにちは" }
  end
end
