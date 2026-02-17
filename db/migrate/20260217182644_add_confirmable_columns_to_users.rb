class AddConfirmableColumnsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :confirmation_token,   :string,   if_not_exists: true
    add_column :users, :confirmed_at,         :datetime, if_not_exists: true
    add_column :users, :confirmation_sent_at, :datetime, if_not_exists: true
    add_column :users, :unconfirmed_email,    :string,   if_not_exists: true

    add_index  :users, :confirmation_token, unique: true, if_not_exists: true
  end
end
