class AddCategoryToDiagnosisQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :diagnosis_questions, :category, :string
  end
end
