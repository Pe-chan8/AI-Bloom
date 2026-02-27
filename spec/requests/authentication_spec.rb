require "rails_helper"

RSpec.describe "Authentication", type: :request do
  it "未ログインだと保護ページにアクセスできない（例：posts#index）" do
    get "/posts"
    get "/posts"
    get "/posts"
    get "/posts"

    expect(response).to have_http_status(:found)
    expect(response.location).to include("/users/sign_in")
  end
end
