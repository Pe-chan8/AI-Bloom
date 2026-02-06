class AnalysesController < ApplicationController
  before_action :authenticate_user!

  def show
    @strength_top5 = StrengthAnalyzer.new(current_user).top5
    @weakness_top5 = WeaknessAnalyzer.new(current_user).top5
  end
end
