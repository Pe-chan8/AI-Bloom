require "test_helper"

class DiagnosesControllerTest < ActionDispatch::IntegrationTest
  # ここで include はなくてもOK（test_helper で済ませる派）
  # include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)  # fixtures/users.yml の :one を使う想定
  end

  test "should get top" do
    get diagnosis_top_url
    assert_response :success
  end

  test "should get questions" do
    get diagnosis_questions_url
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

    sign_in scope: :user, resource: @user

    post diagnosis_result_url, params: {
      answers: {
        q1.id.to_s => "3",
        q2.id.to_s => "5"
      }
    }

    assert_response :success
    assert_select "h1", "ソーシャルタイプ診断 結果"
  end

  test "should redirect when answers empty" do
    post diagnosis_result_url, params: { answers: {} }
    assert_redirected_to diagnosis_questions_url
  end

  test "logged-in user gets social_type saved" do
    DiagnosisQuestion.delete_all
    q1 = DiagnosisQuestion.create!(
      position: 101,
      content: "テスト質問1",
      category: "analytical"
    )

    # ログイン状態にする（fixture のユーザーを使用）
    sign_in @user

    post diagnosis_result_url, params: {
      answers: {
        q1.id.to_s => "5"
      }
    }

    assert_response :success
    @user.reload
    assert_equal "analytical", @user.social_type
  end
end
