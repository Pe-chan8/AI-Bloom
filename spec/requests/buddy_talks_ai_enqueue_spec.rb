require "rails_helper"

RSpec.describe "BuddyTalks AI enqueue", type: :request do
  include ActiveJob::TestHelper

  let(:user) { create_user(email: "t_enqueue@example.com") }

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

  before do
    sign_in user
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "reply で Ai::GenerateBuddyReplyJob が enqueue される" do
    expect {
      post "/buddy_talks/#{buddy_talk.id}/reply", params: { message: "こんにちは" }
    }.to have_enqueued_job(Ai::GenerateBuddyReplyJob)
  end

  it "deep_dive で Ai::GenerateDeepDiveJob が enqueue される" do
    expect {
      post "/buddy_talks/#{buddy_talk.id}/deep_dive", params: {}
    }.to have_enqueued_job(Ai::GenerateDeepDiveJob)
  end

  it "praise_summary で Ai::GeneratePraiseSummaryJob が enqueue される" do
    expect {
      post "/buddy_talks/#{buddy_talk.id}/praise_summary", params: {}
    }.to have_enqueued_job(Ai::GeneratePraiseSummaryJob)
  end

  it "summary で Ai::GenerateSelfPrSummaryJob が enqueue される" do
    expect {
      post "/buddy_talks/#{buddy_talk.id}/summary", params: {}
    }.to have_enqueued_job(Ai::GenerateSelfPrSummaryJob)
  end
end
