require "rails_helper"

RSpec.describe "Diagnoses", type: :request do
  describe "GET /diagnosis" do
    it "診断トップページが表示される" do
      get diagnosis_top_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /diagnosis/questions" do
    it "診断質問ページが表示される" do
      get diagnosis_questions_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /diagnosis/result" do
    it "回答を送信すると診断結果ページにリダイレクトされる" do
      post diagnosis_result_path, params: {
        answers: {
          q1: "a",
          q2: "b"
        }
      }

      expect(response).to have_http_status(:redirect)
    end
  end
end
