require "test_helper"

class MagicLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @inviter = User.create!(
      email: "inviter@example.com",
      first_name: "Invite",
      last_name: "Sender",
      role: "Member"
    )
    @conference = conferences(:one)
    @invitation = Invitation.create!(
      inviter: @inviter,
      conference: @conference,
      first_name: "Guest",
      email: "guest@example.com"
    )
  end

  test "creates and emails a magic link for a new invited user" do
    delivery_payload = nil

    with_replaced_singleton_method(EmailDeliveryService, :notify, ->(**kwargs) {
      delivery_payload = kwargs
      { "messageId" => "<brevo@example.com>" }
    }) do
      assert_difference("MagicLink.count", 1) do
        post magic_links_path, params: {
          magic_link: {
            invitation_token: @invitation.raw_token,
            first_name: "Guest",
            last_name: "Member",
            company_name: "  Example Airlines  "
          }
        }
      end
    end

    magic_link = MagicLink.last

    assert_equal @invitation, magic_link.invitation
    assert_equal "Example Airlines", magic_link.company_name
    assert_equal "guest@example.com", delivery_payload[:to]
    assert_equal "Your FMUG magic link", delivery_payload[:subject]
    assert_equal :brevo, delivery_payload[:delivery]
    assert_includes delivery_payload[:body], "Use this link within 15 minutes"
    token = delivery_payload[:body][/magic-links\/([^\s]+)/, 1]
    assert token.present?
    assert_includes delivery_payload[:body], magic_link_path(token)
    assert_redirected_to root_url
    follow_redirect!
    assert_includes response.body, "Your magic link has been sent. It is valid for 15 minutes."
  end

  test "renders a confirmation page without activating when the magic link is opened" do
    magic_link = @invitation.magic_links.create!(first_name: "Guest", last_name: "Member", company_name: "Example Airlines")

    get magic_link_path(magic_link.raw_token)

    assert_response :success
    assert_includes response.body, "Activate your FMUG account"
    assert_select "form[action='#{activate_magic_link_path}'][method='post']"
    assert_select "input[type='hidden'][name='token'][value='#{magic_link.raw_token}']"

    assert_nil User.find_by(email: "guest@example.com")
    assert_nil session[:user_id]
    assert_nil @invitation.reload.used_at
    assert_nil magic_link.reload.used_at
  end

  test "does not activate a magic link on a HEAD request" do
    magic_link = @invitation.magic_links.create!(first_name: "Guest", last_name: "Member", company_name: "Example Airlines")

    head magic_link_path(magic_link.raw_token)

    assert_response :success
    assert_nil User.find_by(email: "guest@example.com")
    assert_nil session[:user_id]
    assert_nil @invitation.reload.used_at
    assert_nil magic_link.reload.used_at
  end

  test "activates the user and signs them in after confirmation" do
    magic_link = @invitation.magic_links.create!(first_name: "Guest", last_name: "Member", company_name: "Example Airlines")

    post activate_magic_link_path, params: { token: magic_link.raw_token }

    assert_redirected_to root_url
    user = User.find_by(email: "guest@example.com")
    assert_not_nil user
    assert_equal "Guest", user.first_name
    assert_equal "Member", user.last_name
    assert_equal "Example Airlines", user.company_name
    assert_equal user.id, session[:user_id]
    assert @invitation.reload.used_at.present?
    assert magic_link.reload.used_at.present?
  end

  test "rejects a repeated activation POST" do
    magic_link = @invitation.magic_links.create!(first_name: "Guest", last_name: "Member", company_name: "Example Airlines")

    post activate_magic_link_path, params: { token: magic_link.raw_token }
    assert_response :redirect

    assert_no_difference("User.count") do
      post activate_magic_link_path, params: { token: magic_link.raw_token }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Magic Link used is not valid"
  end

  test "activates a legacy magic link without a company name after confirmation" do
    token = "legacy-magic-link-token"
    now = Time.current
    MagicLink.insert_all!([ {
      invitation_id: @invitation.id,
      first_name: "Guest",
      last_name: "Member",
      token_digest: MagicLink.digest(token),
      expires_at: 10.minutes.from_now,
      created_at: now,
      updated_at: now
    } ])

    post activate_magic_link_path, params: { token: }

    assert_redirected_to root_url
    user = User.find_by(email: "guest@example.com")
    assert_not_nil user
    assert_nil user.company_name
    assert @invitation.reload.used_at.present?
    assert MagicLink.find_by_token(token).used_at.present?
  end

  test "rejects expired magic links on GET and POST" do
    magic_link = @invitation.magic_links.create!(first_name: "Guest", last_name: "Member", company_name: "Example Airlines")
    magic_link.update!(expires_at: 1.minute.ago)

    get magic_link_path(magic_link.raw_token)

    assert_response :unprocessable_entity
    assert_includes response.body, "Magic Link used is not valid"
    assert_nil User.find_by(email: "guest@example.com")

    post activate_magic_link_path, params: { token: magic_link.raw_token }

    assert_response :unprocessable_entity
    assert_nil User.find_by(email: "guest@example.com")
  end

  test "rejects unknown magic links on GET and POST" do
    get magic_link_path("not-a-real-token")

    assert_response :unprocessable_entity

    post activate_magic_link_path, params: { token: "not-a-real-token" }

    assert_response :unprocessable_entity
  end

  test "rejects a magic link whose invitation has already been consumed" do
    magic_link = @invitation.magic_links.create!(first_name: "Guest", last_name: "Member", company_name: "Example Airlines")
    @invitation.mark_as_used!

    get magic_link_path(magic_link.raw_token)

    assert_response :unprocessable_entity

    post activate_magic_link_path, params: { token: magic_link.raw_token }

    assert_response :unprocessable_entity
    assert_nil User.find_by(email: "guest@example.com")
  end

  test "activates a campaign invitation once and increments its capacity" do
    campaign = RegistrationCampaign.create!(conference: @conference, created_by: @inviter)
    invitation = Invitation.create!(
      conference: @conference,
      inviter: @inviter,
      registration_campaign: campaign,
      first_name: "Campaign",
      email: "campaign@example.com"
    )
    magic_link = invitation.magic_links.create!(first_name: "Campaign", last_name: "Member", company_name: "Example Airlines")

    post activate_magic_link_path, params: { token: magic_link.raw_token }

    assert_redirected_to root_url
    assert_equal 1, campaign.reload.successful_registrations_count
    assert User.exists?(email: "campaign@example.com")

    post activate_magic_link_path, params: { token: magic_link.raw_token }
    assert_response :unprocessable_entity
    assert_equal 1, campaign.reload.successful_registrations_count
  end

  test "allows user one hundred and rejects user one hundred and one" do
    campaign = RegistrationCampaign.create!(conference: @conference, created_by: @inviter, successful_registrations_count: 99)
    hundredth_invitation = campaign_invitation(campaign, "hundredth@example.com")
    hundredth_link = hundredth_invitation.magic_links.create!(first_name: "Hundredth", last_name: "Member", company_name: "Example Airlines")

    post activate_magic_link_path, params: { token: hundredth_link.raw_token }
    assert_redirected_to root_url
    assert_equal 100, campaign.reload.successful_registrations_count

    next_invitation = campaign_invitation(campaign, "one-hundred-one@example.com")
    next_link = next_invitation.magic_links.create!(first_name: "Next", last_name: "Member", company_name: "Example Airlines")
    assert_no_difference("User.count") do
      post activate_magic_link_path, params: { token: next_link.raw_token }
    end

    assert_response :unprocessable_entity
    assert_equal 100, campaign.reload.successful_registrations_count
    assert_nil next_link.reload.used_at
  end

  test "campaign activation remains valid after campaign expiry or revocation" do
    campaign = RegistrationCampaign.create!(conference: @conference, created_by: @inviter)
    invitation = campaign_invitation(campaign, "pending@example.com")
    magic_link = invitation.magic_links.create!(first_name: "Pending", last_name: "Member", company_name: "Example Airlines")
    campaign.update!(expires_at: 1.minute.ago, revoked_at: Time.current)

    get magic_link_path(magic_link.raw_token)
    assert_response :success
    post activate_magic_link_path, params: { token: magic_link.raw_token }

    assert_redirected_to root_url
    assert_equal 1, campaign.reload.successful_registrations_count
  end

  test "campaign activation for an email that became an account does not consume capacity" do
    campaign = RegistrationCampaign.create!(conference: @conference, created_by: @inviter)
    invitation = campaign_invitation(campaign, "already-created@example.com")
    magic_link = invitation.magic_links.create!(first_name: "Already", last_name: "Created", company_name: "Example Airlines")
    User.create!(email: "already-created@example.com", first_name: "Existing", last_name: "Member", role: "Member")

    post activate_magic_link_path, params: { token: magic_link.raw_token }

    assert_response :unprocessable_entity
    assert_equal 0, campaign.reload.successful_registrations_count
    assert_nil magic_link.reload.used_at
    assert_nil invitation.reload.used_at
  end

  test "campaign activation does not create a case-variant duplicate account" do
    campaign = RegistrationCampaign.create!(conference: @conference, created_by: @inviter)
    invitation = campaign_invitation(campaign, "case-member@example.com")
    magic_link = invitation.magic_links.create!(first_name: "Case", last_name: "Member", company_name: "Example Airlines")
    now = Time.current
    User.insert_all!([ {
      email: "Case-Member@Example.com",
      first_name: "Existing",
      last_name: "Member",
      role: "Member",
      created_at: now,
      updated_at: now
    } ])

    assert_no_difference("User.count") do
      post activate_magic_link_path, params: { token: magic_link.raw_token }
    end

    assert_response :unprocessable_entity
    assert_equal 0, campaign.reload.successful_registrations_count
    assert_nil magic_link.reload.used_at
    assert_nil invitation.reload.used_at
  end

  private

  def campaign_invitation(campaign, email)
    Invitation.create!(
      conference: @conference,
      inviter: @inviter,
      registration_campaign: campaign,
      first_name: "Campaign",
      email:
    )
  end

  test "rejects a blank company name without creating a magic link or sending email" do
    with_replaced_singleton_method(EmailDeliveryService, :notify, ->(**) { flunk "blank company name must not send email" }) do
      assert_no_difference("MagicLink.count") do
        post magic_links_path, params: {
          magic_link: {
            invitation_token: @invitation.raw_token,
            first_name: "Guest",
            last_name: "Member",
            company_name: "  "
          }
        }
      end
    end

    assert_redirected_to root_url(invitation_token: @invitation.raw_token)
    assert_equal "Please enter your first name, last name, and company name.", flash[:alert]
  end

  private

  def with_replaced_singleton_method(object, method_name, implementation)
    singleton_class = object.singleton_class
    original_method = singleton_class.instance_method(method_name) if singleton_class.method_defined?(method_name)

    singleton_class.define_method(method_name, implementation)
    yield
  ensure
    if original_method
      singleton_class.define_method(method_name, original_method)
    else
      singleton_class.remove_method(method_name)
    end
  end
end
