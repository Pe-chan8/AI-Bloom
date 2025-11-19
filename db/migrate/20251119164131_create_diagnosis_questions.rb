class CreateDiagnosisQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :diagnosis_questions do |t|
      t.text :content, null: false
      t.integer :position, null: false

      t.timestamps
    end

    add_index :diagnosis_questions, :position, unique: true
  end
end
