class CreateConferences < ActiveRecord::Migration[8.0]
  def change
    create_table :conferences do |t|
      t.integer :edition
      t.date :start_date
      t.date :end_date
      t.string :host
      t.text :location
      t.boolean :current

      t.timestamps
    end
  end
end
