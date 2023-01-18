class RemoveAuthorAndCategoryFromArticles < ActiveRecord::Migration[7.0]
  def change
    remove_column :articles, :author
    remove_column :articles, :category
  end
end
