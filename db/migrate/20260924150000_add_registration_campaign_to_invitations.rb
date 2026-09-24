class AddRegistrationCampaignToInvitations < ActiveRecord::Migration[8.1]
  def change
    add_reference :invitations, :registration_campaign, foreign_key: true
    add_index :invitations,
      "registration_campaign_id, lower(email)",
      unique: true,
      where: "registration_campaign_id IS NOT NULL",
      name: "index_campaign_invitations_on_normalized_email"
  end
end
