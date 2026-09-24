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
    assert_includes response.body, "min-h-[calc(100vh-7rem)]"
    assert_select "section.flex.w-full.items-center.justify-center", count: 1 do
      assert_select "div.mx-auto.w-full.max-w-xl", count: 1
    end
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

  test "does not create campaign records for a case variant of an existing member" do
    now = Time.current
    User.insert_all!([ {
      email: "CaseReviewer@Example.com",
      first_name: "Existing",
      last_name: "Member",
      role: "Member",
      created_at: now,
      updated_at: now
    } ])

    assert_no_difference([ "Invitation.count", "MagicLink.count" ]) do
      post launch_registration_path(@campaign.raw_token), params: { launch_registration: registration_attributes(email: "casereviewer@example.com") }
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

  test "returns validation feedback without persisting blank last name or company" do
    [ { last_name: "" }, { company_name: "" } ].each do |attributes|
      with_email_delivery(->(**) { flunk "invalid campaign submission must not send email" }) do
        assert_no_difference([ "Invitation.count", "MagicLink.count" ]) do
          post launch_registration_path(@campaign.raw_token), params: { launch_registration: registration_attributes.merge(attributes) }
        end
      end

      assert_response :unprocessable_entity
      assert_includes response.body, "can&#39;t be blank"
      assert_equal 0, @campaign.reload.successful_registrations_count
    end
  end

  test "rolls back campaign records and allows retry when delivery fails" do
    with_email_delivery(->(**) { raise BrevoEmailService::Error, "unavailable" }) do
      assert_no_difference([ "Invitation.count", "MagicLink.count", "User.count" ]) do
        post launch_registration_path(@campaign.raw_token), params: { launch_registration: registration_attributes }
      end
    end

    assert_redirected_to launch_registration_path(@campaign.raw_token)
    assert_equal "We could not send an activation link. Please try again.", flash[:alert]
    assert_equal 0, @campaign.reload.successful_registrations_count

    delivery_payload = nil
    with_email_delivery(->(**kwargs) { delivery_payload = kwargs; {} }) do
      assert_difference([ "Invitation.count", "MagicLink.count" ], 1) do
        post launch_registration_path(@campaign.raw_token), params: { launch_registration: registration_attributes }
      end
    end

    assert_equal "guest@example.com", delivery_payload[:to]
    assert Invitation.last.magic_links.last.usable?
  end

  test "rolls back and retries through the Brevo transport error boundary" do
    with_brevo_api_key do
      with_replaced_singleton_method(Net::HTTP, :start, ->(*) { raise Net::OpenTimeout, "simulated timeout" }) do
        assert_no_difference([ "Invitation.count", "MagicLink.count", "User.count" ]) do
          post launch_registration_path(@campaign.raw_token), params: { launch_registration: registration_attributes }
        end
      end

      assert_redirected_to launch_registration_path(@campaign.raw_token)
      assert_equal "We could not send an activation link. Please try again.", flash[:alert]
      assert_equal 0, @campaign.reload.successful_registrations_count

      delivery_payload = {}
      with_replaced_singleton_method(Net::HTTP, :start, successful_brevo_delivery(delivery_payload)) do
        assert_difference([ "Invitation.count", "MagicLink.count" ], 1) do
          post launch_registration_path(@campaign.raw_token), params: { launch_registration: registration_attributes }
        end
      end

      magic_link = Invitation.last.magic_links.last
      assert magic_link.usable?
      token = JSON.parse(delivery_payload.fetch(:body)).fetch("textContent")[/magic-links\/([^\s]+)/, 1]
      assert token.present?

      post activate_magic_link_path, params: { token: }

      assert_redirected_to root_url
      assert User.exists?(email: "guest@example.com")
      assert_equal 1, @campaign.reload.successful_registrations_count
    end
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

  def successful_brevo_delivery(delivery_payload)
    ->(_hostname, _port, use_ssl:, &block) {
      http = Object.new
      http.define_singleton_method(:request) do |request|
        delivery_payload[:body] = request.body
        Struct.new(:code, :body).new("201", '{"messageId":"<abc123@example.com>"}')
      end
      block.call(http)
    }
  end

  def with_brevo_api_key
    previous_value = ENV["BREVO_API_KEY"]
    ENV["BREVO_API_KEY"] = "test-api-key"
    yield
  ensure
    ENV["BREVO_API_KEY"] = previous_value
  end
end
