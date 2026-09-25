class AllowHistoricalRegistrationCampaigns < ActiveRecord::Migration[8.1]
  def up
    remove_index :registration_campaigns, name: "index_registration_campaigns_on_unique_conference"
  end

  def down
    add_index :registration_campaigns,
      :conference_id,
      unique: true,
      name: "index_registration_campaigns_on_unique_conference"
  end
end
