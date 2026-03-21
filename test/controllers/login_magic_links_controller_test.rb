require "test_helper"

class LoginMagicLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "member@example.com",
      first_name: "Member",
      last_name: "Example",
      role: "Member"
    )
    @conference = conferences(:one)
  end

  test "creates and emails a login magic link for an existing user" do
    delivery_payload = nil

    with_replaced_singleton_method(EmailDeliveryService, :notify, ->(**kwargs) {
      delivery_payload = kwargs
      { "messageId" => "<brevo@example.com>" }
    }) do
      assert_difference("LoginMagicLink.count", 1) do
        post login_magic_links_path, params: { login_magic_link: { email: "member@example.com" } }
      end
    end

    assert_equal "member@example.com", delivery_payload[:to]
    assert_equal "Your FMUG login link", delivery_payload[:subject]
    assert_equal :brevo, delivery_payload[:delivery]
    assert_includes delivery_payload[:body], "log in to the FMUG Community website"
    assert_redirected_to root_url
  end

  test "signs in the user when the login magic link is opened" do
    login_magic_link = @user.login_magic_links.create!

    get login_magic_link_path(login_magic_link.raw_token)

    assert_redirected_to root_url
    follow_redirect!
    assert_includes response.body, "Signed in as member@example.com"
    assert_equal @user.id, session[:user_id]
    assert login_magic_link.reload.used_at.present?
  end

  test "consumes a matching invitation after login magic link proves email ownership" do
    invitation = Invitation.create!(
      inviter: @user,
      conference: @conference,
      first_name: "Member",
      email: @user.email
    )
    delivery_payload = nil

    with_replaced_singleton_method(EmailDeliveryService, :notify, ->(**kwargs) {
      delivery_payload = kwargs
      { "messageId" => "<brevo@example.com>" }
    }) do
      post login_magic_links_path, params: {
        login_magic_link: {
          email: @user.email,
          invitation_token: invitation.raw_token
        }
      }
    end

    token = delivery_payload[:body][/login-magic-links\/([^\s?]+)/, 1]
    assert token.present?
    assert_includes delivery_payload[:body], "invitation_token=#{invitation.raw_token}"
    assert_nil invitation.reload.used_at

    get login_magic_link_path(token), params: { invitation_token: invitation.raw_token }

    assert_redirected_to root_url
    assert invitation.reload.used_at.present?
  end

  test "renders invalid page for expired login magic links" do
    login_magic_link = @user.login_magic_links.create!
    login_magic_link.update!(expires_at: 1.minute.ago)

    get login_magic_link_path(login_magic_link.raw_token)

    assert_response :unprocessable_entity
    assert_includes response.body, "Magic Link used is not valid"
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
