class AddCategoryAndSubcategoryToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :category, :string
    add_column :posts, :subcategory, :string
  end
end
