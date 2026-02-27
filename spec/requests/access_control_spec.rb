require "rails_helper"

RSpec.describe "Access control", type: :request do
  shared_examples "redirects to sign in" do
    it do
      subject
      expect(response).to have_http_status(:found)
      expect(response.location).to include("/users/sign_in")
    end
  end

  describe "GET /posts" do
    subject { get "/posts" }
    it_behaves_like "redirects to sign in"
  end

  describe "GET /buddy_talk" do
    subject { get "/buddy_talk" }
    it_behaves_like "redirects to sign in"
  end

  describe "GET /analytics" do
    subject { get "/analytics" }
    it_behaves_like "redirects to sign in"
  end

  describe "GET /account_setting" do
    subject { get "/account_setting" }
    it_behaves_like "redirects to sign in"
  end

  describe "GET /analyses/social_type_results" do
    subject { get "/analyses/social_type_results" }
    it_behaves_like "redirects to sign in"
  end
end
