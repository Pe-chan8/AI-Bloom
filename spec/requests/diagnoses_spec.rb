require "rails_helper"

RSpec.describe "Diagnoses", type: :request do
  describe "GET /diagnosis" do
    it "診断TOPページが正常に表示される" do
      get diagnosis_top_path

      expect(response).to have_http_status(:ok)
    end
  end
end
