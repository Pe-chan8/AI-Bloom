class AddBuddyToPosts < ActiveRecord::Migration[8.1]
  def change
    add_reference :posts, :buddy, foreign_key: true, null: true
  end
end
