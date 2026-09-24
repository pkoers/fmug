require "test_helper"

class RegistrationCampaignTest < ActiveSupport::TestCase
  setup do
    @admin = User.create!(email: "admin@example.com", first_name: "Admin", last_name: "User", role: "Member", admin: true)
    @campaign = RegistrationCampaign.create!(conference: conferences(:one), created_by: @admin)
  end

  test "creates a digest-backed token with a thirty day expiry" do
    assert @campaign.raw_token.present?
    assert_equal RegistrationCampaign.digest(@campaign.raw_token), @campaign.token_digest
    assert_equal @campaign, RegistrationCampaign.find_by_token(@campaign.raw_token)
    assert_in_delta 30.days.from_now.to_f, @campaign.expires_at.to_f, 1.0
    assert @campaign.accepting_registrations?
  end

  test "reports revoked expired and full campaigns as unavailable" do
    @campaign.revoke!
    assert_equal "revoked", @campaign.status
    assert_not @campaign.accepting_registrations?

    @campaign.update!(revoked_at: nil, expires_at: 1.minute.ago)
    assert_equal "expired", @campaign.status

    @campaign.update!(expires_at: 1.day.from_now, successful_registrations_count: 100)
    assert_equal "full", @campaign.status
    assert_not @campaign.accepting_registrations?
  end
end
