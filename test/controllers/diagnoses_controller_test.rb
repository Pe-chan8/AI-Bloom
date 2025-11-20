require "test_helper"

class DiagnosesControllerTest < ActionDispatch::IntegrationTest
  test "should get top" do
    get diagnosis_top_url
    assert_response :success
  end

  test "should get questions" do
    get diagnosis_questions_url
    assert_response :success
  end

  test "should post result" do
    post diagnosis_result_url, params: { answers: {} }
    assert_response :success
  end
end
