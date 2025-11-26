class CreateBuddies < ActiveRecord::Migration[7.2]
  def change
    create_table :buddies do |t|
      t.string  :code, null: false            # 'normal','analytical' など
      t.string  :name, null: false           # 表示名
      t.text    :description                 # 性格説明
      t.text    :tone_hint                   # 口調・話し方のヒント
      t.text    :persona_prompt              # OpenAI に渡す人格プロンプト
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end

    add_index :buddies, :code, unique: true
  end
end
