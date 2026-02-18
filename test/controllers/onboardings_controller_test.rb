require "test_helper"

class OnboardingsControllerTest < ActionDispatch::IntegrationTest
  test "should get welcome" do
    get onboarding_url
    assert_response :success
  end

  test "should get about" do
    get onboarding_about_url
    assert_response :success
  end
end
