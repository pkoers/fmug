class CreateLeadershipProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :leadership_profiles do |t|
      t.string :chair_name
      t.string :vice_chair_name

      t.timestamps
    end
  end
end
