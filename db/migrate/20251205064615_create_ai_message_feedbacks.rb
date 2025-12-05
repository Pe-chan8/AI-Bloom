class CreateAiMessageFeedbacks < ActiveRecord::Migration[7.2]
  def change
    create_table :ai_message_feedbacks do |t|
      t.references :ai_message, null: false, foreign_key: true
      t.references :user,       null: false, foreign_key: true
      t.integer    :value,      null: false  # 👍: 1, 👎: -1

      t.timestamps
    end

    # 同じユーザーが同じメッセージを何度も評価しないように制約
    add_index :ai_message_feedbacks,
              [ :user_id, :ai_message_id ],
              unique: true
  end
end
