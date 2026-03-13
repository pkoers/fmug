require "test_helper"

class InvitationsControllerTest < ActionController::TestCase
  setup do
    @user = User.create!(
      email: "inviter@example.com",
      first_name: "Invite",
      last_name: "Sender",
      role: "Member"
    )
    @conference = conferences(:one)
  end

  test "should create an invitation for the signed-in user" do
    session[:user_id] = @user.id
    delivery_payload = nil

    with_replaced_singleton_method(EmailDeliveryService, :notify, ->(**kwargs) {
      delivery_payload = kwargs
      { "messageId" => "<brevo@example.com>" }
    }) do
      assert_difference("Invitation.count", 1) do
        post :create, params: {
          invitation: {
            first_name: "Guest",
            email: "guest@example.com"
          }
        }
      end
    end

    invitation = Invitation.last

    assert_equal @user, invitation.inviter
    assert_equal @conference, invitation.conference
    assert_equal "guest@example.com", invitation.email
    assert invitation.token_digest.present?
    assert invitation.expires_at.present?
    assert_nil invitation.used_at
    assert_equal "guest@example.com", delivery_payload[:to]
    assert_equal "Invitation to Conference 1", delivery_payload[:subject]
    assert_equal :brevo, delivery_payload[:delivery]
    assert_equal "FMUG Chair", delivery_payload[:from_name]
    assert_equal "chair@fmug.eu", delivery_payload[:from_email]
    assert_includes delivery_payload[:body], "Hi Guest,"
    assert_includes delivery_payload[:body], "Invitation token:"
    assert_includes delivery_payload[:html_body], "<ul>"
    token = delivery_payload[:body][/invitation_token=([^\s]+)/, 1]
    assert token.present?
    assert_equal invitation, Invitation.find_by_token(token)
    assert_redirected_to root_url
    assert_equal "Invitation sent to guest@example.com.", flash[:notice]
  end

  test "should reject invalid invitations" do
    session[:user_id] = @user.id

    assert_no_difference("Invitation.count") do
      post :create, params: {
        invitation: {
          first_name: "",
          email: "not-an-email"
        }
      }
    end

    assert_redirected_to root_url
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
