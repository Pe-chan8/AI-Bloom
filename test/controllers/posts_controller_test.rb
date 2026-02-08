require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "test-post@example.com",
      password: "password123",
      password_confirmation: "password123",
      nickname: "ぺぺ"
    )

    @post = Post.create!(
      user: @user,
      title: "テスト投稿タイトル",
      body: "最初の投稿",
      posted_at: Time.current,
      visibility: :private,
      category: "仕事",
      subcategory: "テスト",
      mood: "very_positive"
    )

    post user_session_path, params: {
      user: { email: @user.email, password: "password123" }
    }
    follow_redirect! if response.redirect?
  end

  test "should get index when logged in" do
    get posts_path
    assert_response :success

    assert_includes @response.body, "テスト投稿タイトル"
  end

  test "should get edit when logged in" do
    get edit_post_path(@post)
    assert_response :success
  end

  test "should update post" do
    patch post_path(@post), params: {
      post: {
        title: "更新後タイトル",
        visibility: "private",
        category: "仕事",
        subcategory: "テスト"
        # mood / posted_at も必須ならここに追加
      }
    }

    assert_redirected_to buddy_talk_topic_path(@post)

    @post.reload
    assert_equal "更新後タイトル", @post.title
  end
end
