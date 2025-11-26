class AddBuddyToUsers < ActiveRecord::Migration[7.2]
  def change
    add_reference :users, :buddy, foreign_key: true
    # もしくは明示的に:
    # add_reference :users, :buddy, null: true, foreign_key: true
  end
end
