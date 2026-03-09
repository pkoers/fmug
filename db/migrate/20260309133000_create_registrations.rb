class CreateRegistrations < ActiveRecord::Migration[8.1]
  def change
    create_table :registrations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :conference, null: false, foreign_key: true
      t.boolean :attending_physically, null: false

      t.timestamps
    end

    add_index :registrations, [ :user_id, :conference_id ], unique: true
  end
end
