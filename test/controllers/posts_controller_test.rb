require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  # Devise の専用ヘルパーは使わず、自前でログイン処理を書く

  setup do
    @password = "password123"

    @user = User.create!(
      email: "test-post@example.com",
      password: @password,
      password_confirmation: @password
    )

    @post = Post.create!(
      user: @user,
      body: "最初の投稿",
      posted_at: Time.current,
      visibility: :private
    )
  end

  # 共通ログインヘルパー（通常のログインと同じリクエストを送る）
  def log_in(user, password: @password)
    post user_session_path, params: {
      user: {
        email:    user.email,
        password: password
      }
    }
    follow_redirect! # ログイン後のリダイレクトまで追う
  end

  test "should get edit when logged in" do
    log_in(@user)

    get edit_post_path(@post)
    assert_response :success
  end

  test "should update post" do
    log_in(@user)

    patch post_path(@post), params: {
      post: {
        body: "更新後の投稿",
        visibility: "private"
      }
    }

    assert_redirected_to root_path
    @post.reload
    assert_equal "更新後の投稿", @post.body
  end
end
