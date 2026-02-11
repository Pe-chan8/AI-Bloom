class AddCategoryToAiMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :ai_messages, :category, :string, null: false, default: "all"
    add_column :ai_messages, :subcategory, :string
    add_index  :ai_messages, [:user_id, :kind, :category, :subcategory, :created_at],
              name: "idx_ai_messages_analysis_scope"
  end
end
