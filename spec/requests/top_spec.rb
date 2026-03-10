require "rails_helper"

RSpec.describe "Top", type: :request do
  describe "GET /" do
    it "onboarding にリダイレクトされる" do
      get root_path

      expect(response).to redirect_to(onboarding_path)
    end
  end

  describe "GET /top/index" do
    it "onboarding にリダイレクトされる" do
      get top_index_path

      expect(response).to redirect_to(onboarding_path)
    end
  end
end
