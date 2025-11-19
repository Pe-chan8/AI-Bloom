require "test_helper"

class DiagnosesControllerTest < ActionDispatch::IntegrationTest
  test "should get top" do
    get diagnosis_top_path

    assert_response :success
  end
end
