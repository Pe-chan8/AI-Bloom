module TestHelpers
  def create_user(email: "test@example.com", password: "password", nickname: "テストユーザー")
    attrs = {
      email: email,
      password: password,
      password_confirmation: password,
      nickname: nickname
    }

    attrs[:confirmed_at] = Time.current if User.new.respond_to?(:confirmed_at)

    User.create!(attrs)
  end
end
