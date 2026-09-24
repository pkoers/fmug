require "test_helper"

class RegistrationCampaignsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: "admin@example.com", first_name: "Admin", last_name: "User", role: "Member", admin: true)
    @member = User.create!(email: "member@example.com", first_name: "Member", last_name: "User", role: "Member")
  end

  test "requires administrator access" do
    get registration_campaigns_path
    assert_redirected_to root_path

    login_link = @member.login_magic_links.create!
    get login_magic_link_path(login_link.raw_token)
    get registration_campaigns_path
    assert_redirected_to root_path
  end

  test "admin creates views and revokes a campaign" do
    sign_in_as(@admin)

    assert_difference("RegistrationCampaign.count", 1) do
      post registration_campaigns_path
    end

    campaign = RegistrationCampaign.last
    assert_response :created
    assert_includes response.body, "/launch-registration/"
    assert_equal @admin, campaign.created_by
    assert_equal conferences(:one), campaign.conference

    post revoke_registration_campaign_path(campaign)
    assert_redirected_to registration_campaign_path(campaign)
    assert campaign.reload.revoked?
  end

  test "does not create a replacement campaign after the first campaign changes state" do
    sign_in_as(@admin)
    post registration_campaigns_path
    campaign = RegistrationCampaign.last

    [ -> { campaign.revoke! }, -> { campaign.update!(revoked_at: nil, expires_at: 1.minute.ago) }, -> { campaign.update!(expires_at: 1.day.from_now, successful_registrations_count: 100) } ].each do |change_state|
      change_state.call

      assert_no_difference("RegistrationCampaign.count") do
        post registration_campaigns_path
      end

      assert_redirected_to registration_campaign_path(campaign)
      assert_equal campaign, RegistrationCampaign.find_by(conference: conferences(:one))
    end
  end

  test "does not create a second campaign for an active conference" do
    sign_in_as(@admin)
    post registration_campaigns_path
    campaign = RegistrationCampaign.last

    assert_no_difference("RegistrationCampaign.count") do
      post registration_campaigns_path
    end

    assert_redirected_to registration_campaign_path(campaign)
    get new_registration_campaign_path
    assert_redirected_to registration_campaign_path(campaign)
  end

  private

  def sign_in_as(user)
    login_link = user.login_magic_links.create!
    get login_magic_link_path(login_link.raw_token)
  end
end
