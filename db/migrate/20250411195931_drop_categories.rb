class DropCategories < ActiveRecord::Migration[8.0]
  def up
    drop_table :categories
  end
end
