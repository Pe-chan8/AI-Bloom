class CreateAiMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :ai_messages do |t|
      t.references :user,  null: false, foreign_key: true
      t.references :buddy, null: true,  foreign_key: true
      t.references :post,  null: true,  foreign_key: true

      t.integer :kind,     null: false, default: 2
      t.text    :content,  null: false
      t.integer :sentiment

      t.timestamps
    end
  end
end
