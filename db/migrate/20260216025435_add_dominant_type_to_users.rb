class AddDominantTypeToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :dominant_type, :string
    add_index  :users, :dominant_type
  end
end
