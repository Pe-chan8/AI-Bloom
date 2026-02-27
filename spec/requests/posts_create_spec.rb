require "rails_helper"

RSpec.describe "Posts", type: :request do
  it "ログイン済みなら posts#index に入れる" do
    user = create_user(email: "t@example.com")
    sign_in user

    get "/posts"
    expect(response).to have_http_status(:ok)
  end
end
