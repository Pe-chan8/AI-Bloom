class CreateAiLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :ai_logs do |t|
      t.references :user,       null: false, foreign_key: true
      t.references :post,                    foreign_key: true
      t.references :ai_message,             foreign_key: true

      t.string  :provider, null: false, default: "openai"
      t.string  :model,    null: false
      t.string  :variant   # A/Bテスト用。

      t.integer :prompt_tokens
      t.integer :completion_tokens
      t.integer :total_tokens

      t.integer :latency_ms # 応答時間(ms)

      t.string  :status, null: false, default: "success" # "success" or "error"
      t.string  :error_class
      t.text    :error_message

      t.datetime :requested_at
      t.datetime :responded_at

      t.timestamps
    end

    add_index :ai_logs, [:user_id, :created_at]
    add_index :ai_logs, [:post_id, :created_at]
    add_index :ai_logs, :status
  end
end
