require "test_helper"

class LaunchRegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: "admin@example.com", first_name: "Admin", last_name: "User", role: "Member", admin: true)
    @campaign = RegistrationCampaign.create!(conference: conferences(:one), created_by: @admin)
  end

  test "renders an active campaign registration form" do
    get launch_registration_path(@campaign.raw_token)

    assert_response :success
    assert_includes response.body, "Send activation link"
  end

  test "submits a campaign invitation and normal magic link without creating a user" do
    delivery_payload = nil

    with_email_delivery(->(**kwargs) { delivery_payload = kwargs; {} }) do
      assert_difference([ "Invitation.count", "MagicLink.count" ], 1) do
        post launch_registration_path(@campaign.raw_token), params: { launch_registration: registration_attributes }
      end
    end

    invitation = Invitation.last
    assert_equal @campaign, invitation.registration_campaign
    assert_equal @admin, invitation.inviter
    assert_equal @campaign.conference, invitation.conference
    assert_equal "guest@example.com", delivery_payload[:to]
    assert_nil User.find_by(email: "guest@example.com")
    assert_equal 0, @campaign.reload.successful_registrations_count
  end

  test "does not create campaign records for an existing member" do
    User.create!(email: "guest@example.com", first_name: "Existing", last_name: "Member", role: "Member")

    assert_no_difference([ "Invitation.count", "MagicLink.count" ]) do
      post launch_registration_path(@campaign.raw_token), params: { launch_registration: registration_attributes }
    end

    assert_equal 0, @campaign.reload.successful_registrations_count
    assert_includes flash[:notice], "If your details are eligible"
  end

  test "does not create records for invalid input" do
    assert_no_difference([ "Invitation.count", "MagicLink.count" ]) do
      post launch_registration_path(@campaign.raw_token), params: { launch_registration: registration_attributes(email: "bad") }
    end

    assert_response :unprocessable_entity
    assert_equal 0, @campaign.reload.successful_registrations_count
  end

  test "rejects unknown revoked expired and full campaigns" do
    get launch_registration_path("not-a-real-token")
    assert_response :unprocessable_entity

    @campaign.revoke!
    get launch_registration_path(@campaign.raw_token)
    assert_response :unprocessable_entity

    @campaign.update!(revoked_at: nil, expires_at: 1.minute.ago)
    get launch_registration_path(@campaign.raw_token)
    assert_response :unprocessable_entity

    @campaign.update!(expires_at: 1.day.from_now, successful_registrations_count: 100)
    get launch_registration_path(@campaign.raw_token)
    assert_response :unprocessable_entity
  end

  private

  def registration_attributes(email: "guest@example.com")
    { first_name: "Guest", last_name: "Member", company_name: "Example Airlines", email: }
  end

  def with_email_delivery(implementation)
    singleton_class = EmailDeliveryService.singleton_class
    original_method = singleton_class.instance_method(:notify)
    singleton_class.define_method(:notify, implementation)
    yield
  ensure
    singleton_class.define_method(:notify, original_method)
  end
end
