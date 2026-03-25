require "rails_helper"

RSpec.describe "BuddyTalks enqueue", type: :request do
  include ActiveJob::TestHelper

  let(:password) { "password123" }
  let(:user) do
    create(
      :user,
      email: "test_enqueue@example.com",
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

  it "reply で Ai::GenerateBuddyReplyJob が呼ばれる（perform_later）" do
    expect do
      post reply_buddy_talk_path(post_record), params: { message: "ありがとう" }
    end.to have_enqueued_job(Ai::GenerateBuddyReplyJob)
  end
end
