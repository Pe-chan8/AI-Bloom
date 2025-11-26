require "test_helper"

class DiagnosesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should get top" do
    get diagnosis_top_url
    assert_response :success
  end

  test "should get questions" do
    get diagnosis_questions_url
    assert_response :success
  end

  test "should_post_result" do
    post diagnosis_result_url, params: {
      answers: { "1" => "3", "2" => "4" } # 実際のパラメータに合わせて調整
    }
    assert_response :success
  end

  test "should_redirect_when_answers_empty" do
    post diagnosis_result_url, params: { answers: {} }
    assert_redirected_to diagnosis_questions_url
  end
end
