class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.references :company, null: false, foreign_key: true
      t.string :role, null: false

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
