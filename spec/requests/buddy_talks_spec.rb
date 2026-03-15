require "rails_helper"

RSpec.describe "BuddyTalks", type: :request do
  let(:password) { "password123" }

  let(:user) do
    create(
      :user,
      email: "test@example.com",
      password: password,
      password_confirmation: password
    )
  end

  let(:post_record) { create(:post, user: user) }

  before do
    post user_session_path, params: {
      user: {
        email: user.email,
        password: password
      }
    }
  end

  describe "GET /buddy_talk" do
    it "BuddyTalkページのレスポンスを確認する" do
      get buddy_talk_path

      p response.status
      p response.headers["Location"]

      expect(response).to have_http_status(:found)
    end
  end

  describe "GET /buddy_talks/:id" do
    it "トピックページのレスポンスを確認する" do
      get buddy_talk_topic_path(post_record)

      p response.status
      p response.headers["Location"]

      expect(response).to have_http_status(:found)
    end
  end
end
