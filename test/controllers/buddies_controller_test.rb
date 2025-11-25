require "test_helper"

class BuddiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @buddy = buddies(:normal) # buddies.yml に normal があれば
  end

  test "should_get_index" do
    get buddies_url
    assert_response :success
  end

  test "should_get_select" do
    post select_buddy_url(@buddy)
    assert_redirected_to buddies_url
    assert_equal @buddy, @user.reload.buddy
  end
end
