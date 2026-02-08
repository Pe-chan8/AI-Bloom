class AddCascadeDeleteToPostForeignKeys < ActiveRecord::Migration[8.1]
  def change
    # ai_logs -> posts
    remove_foreign_key :ai_logs, :posts
    add_foreign_key :ai_logs, :posts, on_delete: :cascade

    # buddy_messages -> posts
    remove_foreign_key :buddy_messages, :posts
    add_foreign_key :buddy_messages, :posts, on_delete: :cascade
  end
end
