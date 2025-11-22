require "test_helper"

class DiagnosesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @user = users(:one)
  end

  test "should get top" do
    get :top
    assert_response :success
  end

  test "should get questions" do
    get :questions
    assert_response :success
  end

  test "should post result" do
    DiagnosisQuestion.delete_all

    q1 = DiagnosisQuestion.create!(
      position: 101,
      content: "テスト内容1",
      category: "analytical"
    )

    q2 = DiagnosisQuestion.create!(
      position: 102,
      content: "テスト内容2",
      category: "expressive"
    )

    # ログインしてリクエスト
    sign_in @user

    post :result, params: {
      answers: {
        q1.id.to_s => "3",
        q2.id.to_s => "5"
      }
    }

    assert_response :success
    assert_select "h1", "ソーシャルタイプ診断 結果"
  end

  test "should redirect when answers empty" do
    post :result, params: { answers: {} }
    assert_redirected_to diagnosis_questions_url
  end

  test "logged-in user gets social_type saved" do
    DiagnosisQuestion.delete_all

    q1 = DiagnosisQuestion.create!(
      position: 101,
      content: "テスト質問1",
      category: "analytical"
    )

    sign_in @user

    post :result, params: {
      answers: {
        q1.id.to_s => "5"
      }
    }

    assert_response :success
    @user.reload
    assert_equal "analytical", @user.social_type
  end
end
