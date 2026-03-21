# frozen_string_literal: true

RSpec.shared_examples "未ログイン時にログイン画面へリダイレクトされる" do
  it "ログイン画面へリダイレクトされる" do
    subject
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to(new_user_session_path)
  end
end
