class ChangeFkAiLogsAiMessageOnDeleteCascade < ActiveRecord::Migration[8.1]
  def change
    # 既存FKを落として付け直す
    remove_foreign_key :ai_logs, :ai_messages

    add_foreign_key :ai_logs, :ai_messages, on_delete: :cascade
  end
end
