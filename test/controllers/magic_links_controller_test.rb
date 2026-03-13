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
            last_name: "Member"
          }
        }
      end
    end

    magic_link = MagicLink.last

    assert_equal @invitation, magic_link.invitation
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

  test "activates the user and signs them in when the magic link is opened" do
    magic_link = @invitation.magic_links.create!(first_name: "Guest", last_name: "Member")

    get magic_link_path(magic_link.raw_token)

    assert_redirected_to root_url
    follow_redirect!

    user = User.find_by(email: "guest@example.com")
    assert_not_nil user
    assert_equal "Guest", user.first_name
    assert_equal "Member", user.last_name
    assert_includes response.body, "Signed in as guest@example.com"
    assert_equal user.id, session[:user_id]
    assert @invitation.reload.used_at.present?
    assert magic_link.reload.used_at.present?
  end

  test "rejects expired magic links" do
    magic_link = @invitation.magic_links.create!(first_name: "Guest", last_name: "Member")
    magic_link.update!(expires_at: 1.minute.ago)

    get magic_link_path(magic_link.raw_token)

    assert_response :unprocessable_entity
    assert_includes response.body, "Magic Link used is not valid"
    assert_nil User.find_by(email: "guest@example.com")
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
