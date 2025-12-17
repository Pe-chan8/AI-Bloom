class AddOnboardedAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :onboarded_at, :datetime
    add_index :users, :onboarded_at
  end
end
