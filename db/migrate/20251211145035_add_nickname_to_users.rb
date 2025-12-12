class AddNicknameToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :nickname, :string
    User.reset_column_information
    User.where(nickname: [nil, ""]).find_each do |user|
      user.update_column(:nickname, user.email.split("@").first)
    end
  end
end
