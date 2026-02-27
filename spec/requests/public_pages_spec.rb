require "rails_helper"

RSpec.describe "Public pages", type: :request do
  it "TOP（/）は未ログインならオンボーディングへリダイレクトされる" do
    get "/"
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/onboarding")
  end

  it "オンボーディングが表示できる" do
    get "/onboarding"
    expect(response).to have_http_status(:ok)
  end

  it "診断TOPが表示できる" do
    get "/diagnosis"
    expect(response).to have_http_status(:ok)
  end

  it "利用規約/プライバシーが表示できる" do
    get "/terms"
    expect(response).to have_http_status(:ok)

    get "/privacy"
    expect(response).to have_http_status(:ok)
  end

  it "お問い合わせフォームが表示できる" do
    get "/feedback"
    expect(response).to have_http_status(:ok)
  end

  it "ヘルスチェックが表示できる" do
    get "/up"
    expect(response).to have_http_status(:ok)
  end
end
