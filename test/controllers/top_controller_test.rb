require "test_helper"

class TopControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)   # users.yml にあるユーザーFIXTURE
    sign_in @user
  end

  test "should get index" do
    get root_url
    assert_response :success
  end
end
