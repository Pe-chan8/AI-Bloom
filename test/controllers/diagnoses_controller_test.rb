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
    # テスト用の質問レコードを作成（カテゴリ付き）
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

    post diagnosis_result_url, params: {
      answers: {
        q1.id.to_s => "3", # analytical に3点
        q2.id.to_s => "5"  # expressive に5点
      }
    }

    # 成功ステータスを期待
    assert_response :success

    # 結果画面の見出しが出ているか簡単にチェック
    assert_select "h1", "ソーシャルタイプ診断 結果"
  end

  test "should redirect when answers empty" do
    post diagnosis_result_url, params: { answers: {} }
    assert_redirected_to diagnosis_questions_url
  end

  test "logged-in user gets social_type saved" do
    # ユーザー作成（Devise の helper があればそれを使用）
    user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    # 質問レコード（positionは他と被らないように100番台）
    DiagnosisQuestion.delete_all
    q1 = DiagnosisQuestion.create!(
      position: 101,
      content: "テスト質問1",
      category: "analytical"
    )

    # ログイン状態にする
    sign_in user

    post diagnosis_result_url, params: {
      answers: {
        q1.id.to_s => "5"
      }
    }

    assert_response :success
    user.reload
    assert_equal "analytical", user.social_type
  end
end
