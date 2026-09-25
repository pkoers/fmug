require "test_helper"

class RegistrationCampaignsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: "admin@example.com", first_name: "Admin", last_name: "User", role: "Member", admin: true)
    @member = User.create!(email: "member@example.com", first_name: "Member", last_name: "User", role: "Member")
  end

  test "requires administrator access" do
    campaign = RegistrationCampaign.create!(conference: conferences(:one), created_by: @admin)

    [
      -> { get registration_campaigns_path },
      -> { get new_registration_campaign_path },
      -> { post registration_campaigns_path },
      -> { get registration_campaign_path(campaign) },
      -> { post revoke_registration_campaign_path(campaign) }
    ].each do |request|
      request.call
      assert_redirected_to root_path
    end

    login_link = @member.login_magic_links.create!
    get login_magic_link_path(login_link.raw_token)

    [
      -> { get registration_campaigns_path },
      -> { get new_registration_campaign_path },
      -> { post registration_campaigns_path },
      -> { get registration_campaign_path(campaign) },
      -> { post revoke_registration_campaign_path(campaign) }
    ].each do |request|
      request.call
      assert_redirected_to root_path
    end
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

  test "admin creates replacements after revoked expired and full campaigns" do
    sign_in_as(@admin)
    post registration_campaigns_path
    campaign = RegistrationCampaign.last

    [ -> { campaign.revoke! }, -> { campaign.update!(revoked_at: nil, expires_at: 1.minute.ago) }, -> { campaign.update!(expires_at: 1.day.from_now, successful_registrations_count: 100) } ].each do |change_state|
      change_state.call

      assert_difference("RegistrationCampaign.count", 1) do
        post registration_campaigns_path
      end

      replacement = RegistrationCampaign.last
      assert_response :created
      assert_not_equal campaign, replacement
      assert_not_equal campaign.token_digest, replacement.token_digest
      assert_equal 0, replacement.successful_registrations_count
      assert_equal RegistrationCampaign::REGISTRATION_LIMIT, replacement.registration_limit
      assert_in_delta 30.days.from_now.to_f, replacement.expires_at.to_f, 1.0

      campaign = replacement
    end

    assert_equal 4, conferences(:one).registration_campaigns.count
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

  test "shows the start action only when the current conference has no active campaign" do
    sign_in_as(@admin)
    campaign = RegistrationCampaign.create!(conference: conferences(:one), created_by: @admin)

    get registration_campaigns_path
    assert_not_includes response.body, "Start new campaign"

    campaign.revoke!

    get registration_campaigns_path
    assert_includes response.body, "Start new campaign"

    get registration_campaign_path(campaign)
    assert_includes response.body, "Start new campaign"
    assert_not_includes response.body, "Revoke campaign"
  end

  private

  def sign_in_as(user)
    login_link = user.login_magic_links.create!
    get login_magic_link_path(login_link.raw_token)
  end
end
