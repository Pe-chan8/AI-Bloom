require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(
      email: "test-post@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    @post = Post.create!(
      user: @user,
      body: "最初の投稿",
      posted_at: Time.current,
      visibility: :private
    )
  end

  test "should get index when logged in" do
    sign_in @user
    get posts_path
    assert_response :success
    assert_includes @response.body, "最初の投稿"
  end

  test "should get edit when logged in" do
    sign_in @user
    get edit_post_path(@post)
    assert_response :success
  end

  test "should update post" do
    sign_in @user

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
