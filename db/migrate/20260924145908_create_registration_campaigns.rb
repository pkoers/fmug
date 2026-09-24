class CreateRegistrationCampaigns < ActiveRecord::Migration[8.1]
  def change
    create_table :registration_campaigns do |t|
      t.references :conference, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.integer :registration_limit, null: false, default: 100
      t.integer :successful_registrations_count, null: false, default: 0

      t.timestamps
    end

    add_index :registration_campaigns, :token_digest, unique: true
    add_check_constraint :registration_campaigns, "registration_limit = 100", name: "registration_campaigns_fixed_limit"
    add_check_constraint :registration_campaigns, "successful_registrations_count >= 0", name: "registration_campaigns_nonnegative_count"
    add_check_constraint :registration_campaigns,
      "successful_registrations_count <= registration_limit",
      name: "registration_campaigns_count_within_limit"
  end
end
