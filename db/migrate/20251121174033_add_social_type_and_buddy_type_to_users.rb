class AddSocialTypeAndBuddyTypeToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :social_type, :string
    add_column :users, :recommended_buddy_type, :string
  end
end
