module TestHelpers
  def create_user(email: nil, password: "password", nickname: "テストユーザー")
    unique_email = email || "test_#{SecureRandom.hex(4)}@example.com"

    attrs = {
      email: unique_email,
      password: password,
      password_confirmation: password,
      nickname: nickname
    }

    attrs[:confirmed_at] = Time.current if User.new.respond_to?(:confirmed_at)

    User.create!(attrs)
  end
end
