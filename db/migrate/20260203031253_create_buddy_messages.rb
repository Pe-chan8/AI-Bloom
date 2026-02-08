class CreateBuddyMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :buddy_messages do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.integer :role, null: false, default: 0
      t.text :content, null: false

      t.timestamps
    end

    add_index :buddy_messages, [ :post_id, :created_at ]
  end
end
