# frozen_string_literal: true

RSpec.shared_context "ログイン済みユーザー" do
  let(:user) { create(:user) }

  before do
    sign_in user
  end
end
