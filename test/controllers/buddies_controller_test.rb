require "test_helper"

class BuddiesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get buddies_index_url
    assert_response :success
  end

  test "should get select" do
    get buddies_select_url
    assert_response :success
  end
end
