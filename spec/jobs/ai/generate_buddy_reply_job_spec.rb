require "rails_helper"

RSpec.describe Ai::GenerateBuddyReplyJob, type: :job do
  include ActiveJob::TestHelper

  it "実行しても例外にならない（外部AIはスタブ）" do
    user = create_user(email: "job1@example.com")

    buddy = Buddy.find_by(code: "normal") || Buddy.create!(code: "normal", name: "ノーマル")

    category =
      if Post.respond_to?(:categories) && Post.categories.is_a?(Hash) && Post.categories.any?
        Post.categories.keys.first
      else
        "general"
      end

    post = user.posts.create!(
      body: "テスト投稿",
      posted_at: Time.zone.now,
      title: "テスト",
      category: category,
      buddy: buddy
    )

    allow(Openai::Client).to receive(:new).and_return(double)

    expect {
      described_class.perform_now(
        post_id: post.id,
        user_id: user.id,
        buddy_id: buddy.id,
        placeholder_id: "spec_placeholder"
      )
    }.not_to raise_error
  end
end
