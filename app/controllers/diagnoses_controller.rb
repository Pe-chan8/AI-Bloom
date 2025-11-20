class DiagnosesController < ApplicationController
  def top
  end

  def questions
    @questions = DiagnosisQuestion.order(:position)
  end

  def result
    # ロジック未実装/ひとまず受け取った回答を読むだけ
    @answers = params[:answers] || {}
  end
end
