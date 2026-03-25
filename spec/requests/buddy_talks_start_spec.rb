require "rails_helper"

RSpec.describe "BuddyTalks", type: :request do
  include ActiveJob::TestHelper

  let(:password) { "password123" }
  let(:user) do
    create(
      :user,
      email: "test_start@example.com",
      password: password,
      password_confirmation: password
    )
  end
  let!(:buddy) { create(:buddy) }

  before do
    post user_session_path, params: {
      user: {
        email: user.email,
        password: password
      }
    }
  end

  describe "POST /buddy_talk/start" do
    it "ログイン済みで開始すると Ai::GenerateBuddyReplyJob が enqueue される" do
      expect do
        post start_buddy_talk_path, params: {
          post: {
            title: "今日のこと",
            body: "ちょっと疲れた",
            mood: "positive",
            posted_at: Time.zone.now,
            category: "work"
          }
        }
      end.to have_enqueued_job(Ai::GenerateBuddyReplyJob)
    end
  end
end
