require "rails_helper"

RSpec.describe "BuddyTalks POST /buddy_talk/start", type: :request do
  include ActiveJob::TestHelper

  let(:user) { create_user(email: "t_start@example.com") }

  before do
    sign_in user
    clear_enqueued_jobs
  end

  def valid_category
    if Post.respond_to?(:categories) && Post.categories.is_a?(Hash) && Post.categories.any?
      Post.categories.keys.first
    else
      "general"
    end
  end

  it "ログイン済みで開始すると Ai::GenerateBuddyReplyJob が enqueue される" do
    expect {
      post "/buddy_talk/start", params: {
        post: {
          body: "開始テスト",
          posted_at: Time.zone.now,
          title: "テスト",
          category: valid_category
        }
      }
    }.to have_enqueued_job(Ai::GenerateBuddyReplyJob)
  end
end
