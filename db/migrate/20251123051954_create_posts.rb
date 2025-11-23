class CreatePosts < ActiveRecord::Migration[7.2]
  def change
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true

      t.text    :body, null: false
      t.text    :image_url
      t.integer :visibility, null: false, default: 0  # private
      t.integer :mood                                  # optional
      t.text    :ai_summary
      t.datetime :posted_at

      t.timestamps
    end

    add_index :posts, [ :visibility, :posted_at ]
  end
end
