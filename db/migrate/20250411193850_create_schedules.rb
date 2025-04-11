class CreateSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :schedules do |t|
      t.integer :edition
      t.references :conference, null: false, foreign_key: true
      t.date :date
      t.time :time
      t.integer :length
      t.text :description

      t.timestamps
    end
  end
end
