class CreateSocialTypeResults < ActiveRecord::Migration[8.1]
  def change
    create_table :social_type_results do |t|
      t.references :user, null: false, foreign_key: true

      # 将来16分類化を見据えて保持
      t.integer :schema_version, null: false, default: 4

      # 代表タイプ（今は4種類）
      t.integer :dominant_type, null: false

      # 各タイプの点数（JSON）
      # 例: { "amiable": 7, "analytical": 3, "driving": 5, "expressive": 2 }
      t.jsonb :scores, null: false, default: {}

      t.string :question_set_key
      t.datetime :diagnosed_at, null: false

      t.timestamps
    end

    add_index :social_type_results, :diagnosed_at
  end
end
