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

    assert_difference("Invitation.count", 1) do
      post :create, params: {
        invitation: {
          first_name: "Guest",
          email: "guest@example.com"
        }
      }
    end

    invitation = Invitation.last
    body = flash[:invitation_email_body]

    assert_equal @user, invitation.inviter
    assert_equal @conference, invitation.conference
    assert_equal "guest@example.com", invitation.email
    assert invitation.token_digest.present?
    assert invitation.expires_at.present?
    assert_nil invitation.used_at
    assert_includes body, "Hi Guest,"
    assert_includes body, "Invitation token:"
    assert_includes body, "Use this invitation link to register:"
    token = body[/invitation_token=([^\s]+)/, 1]
    assert token.present?
    assert_equal invitation, Invitation.find_by_token(token)
    assert_redirected_to root_url
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

    assert_nil flash[:invitation_email_body]
    assert_redirected_to root_url
  end
end
