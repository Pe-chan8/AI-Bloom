class AnalysesController < ApplicationController
  before_action :authenticate_user!

  def show
    analyzer = StrengthAnalyzer.new(current_user)
    @top_strengths = analyzer.top_strengths
  end
end
