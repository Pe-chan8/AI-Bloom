require "test_helper"

class DiagnosesControllerTest < ActionDispatch::IntegrationTest
  test "should get top" do
    get diagnoses_top_url
    assert_response :success
  end
end
