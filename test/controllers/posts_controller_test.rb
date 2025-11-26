require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    # ログインユーザーを作成
    @user = User.create!(
      email: "test-post@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    # 紐づく投稿を作成
    @post = Post.create!(
      user: @user,
      body: "最初の投稿",
      posted_at: Time.current,
      visibility: :private
    )

    # ★ Devise のログインフォーム経由でログインする
    post user_session_path, params: {
      user: {
        email:    @user.email,
        password: "password123"
      }
    }

    # ログイン後にリダイレクトがあれば追従
    follow_redirect! if response.redirect?
  end

  test "should get index when logged in" do
    get posts_path
    assert_response :success
    assert_includes @response.body, "最初の投稿"
  end

  test "should get edit when logged in" do
    get edit_post_path(@post)
    assert_response :success
  end

  test "should update post" do
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
