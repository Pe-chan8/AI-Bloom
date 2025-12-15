require "test_helper"

class OnboardingsControllerTest < ActionDispatch::IntegrationTest
  test "should get welcome" do
    get onboardings_welcome_url
    assert_response :success
  end

  test "should get about" do
    get onboardings_about_url
    assert_response :success
  end
end
