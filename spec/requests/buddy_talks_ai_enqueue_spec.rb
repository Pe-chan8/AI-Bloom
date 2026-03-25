require "rails_helper"

RSpec.describe "BuddyTalks AI enqueue", type: :request do
  include ActiveJob::TestHelper

  let(:password) { "password123" }
  let(:user) do
    create(
      :user,
      email: "test_ai_enqueue@example.com",
      password: password,
      password_confirmation: password
    )
  end
  let!(:buddy) { create(:buddy) }
  let!(:post_record) { create(:post, user: user, buddy: buddy) }

  before do
    post user_session_path, params: {
      user: {
        email: user.email,
        password: password
      }
    }
  end

  it "reply で Ai::GenerateBuddyReplyJob が enqueue される" do
    expect do
      post reply_buddy_talk_path(post_record), params: { message: "返信して" }
    end.to have_enqueued_job(Ai::GenerateBuddyReplyJob)
  end

  it "deep_dive で Ai::GenerateDeepDiveJob が enqueue される" do
    expect do
      post deep_dive_buddy_talk_path(post_record)
    end.to have_enqueued_job(Ai::GenerateDeepDiveJob)
  end

  it "praise_summary で Ai::GeneratePraiseSummaryJob が enqueue される" do
    expect do
      post praise_summary_buddy_talk_path(post_record)
    end.to have_enqueued_job(Ai::GeneratePraiseSummaryJob)
  end

  it "summary で Ai::GenerateSelfPrSummaryJob が enqueue される" do
    expect do
      post summary_buddy_talk_path(post_record)
    end.to have_enqueued_job(Ai::GenerateSelfPrSummaryJob)
  end
end
