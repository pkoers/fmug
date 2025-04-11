class DropArticles < ActiveRecord::Migration[8.0]
  def up
    drop_table :articles
  end
end
