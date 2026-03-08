class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.string :iata_code

      t.timestamps
    end

    add_index :companies, :name
    add_index :companies, :iata_code, unique: true
  end
end
