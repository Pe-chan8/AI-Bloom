class AddCurrentBuddyIdToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :current_buddy_id, :bigint
    add_index  :users, :current_buddy_id
  end
end
