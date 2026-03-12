require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @inviter = User.create!(
      email: "inviter@example.com",
      first_name: "Invite",
      last_name: "Sender",
      role: "Member"
    )
    @conference = conferences(:one)
  end

  test "shows success message for a valid invitation token when invited email belongs to an existing user" do
    User.create!(
      email: "guest@example.com",
      first_name: "Existing",
      last_name: "Guest",
      role: "Member"
    )
    invitation = Invitation.create!(
      inviter: @inviter,
      conference: @conference,
      first_name: "Guest",
      email: "guest@example.com"
    )

    get root_path(invitation_token: invitation.raw_token)

    assert_response :success
    assert_includes response.body, "Token validated and still valid"
    assert_includes response.body, "you&#39;re already a user"
    assert_not_includes response.body, "welcome new user"
    assert_not_includes response.body, "Invite attendee"
    assert_not_includes response.body, "Register me for the conference"
  end

  test "shows success message for a valid invitation token when invited email is new" do
    invitation = Invitation.create!(
      inviter: @inviter,
      conference: @conference,
      first_name: "Guest",
      email: "guest@example.com"
    )

    get root_path(invitation_token: invitation.raw_token)

    assert_response :success
    assert_includes response.body, "Token validated and still valid"
    assert_includes response.body, "welcome new user"
    assert_not_includes response.body, "you&#39;re already a user"
    assert_not_includes response.body, "Invite attendee"
    assert_not_includes response.body, "Register me for the conference"
  end

  test "shows invalid message for an unknown invitation token" do
    get root_path(invitation_token: "not-a-real-token")

    assert_response :success
    assert_includes response.body, "Invalid invitation token"
    assert_not_includes response.body, "Invite attendee"
    assert_not_includes response.body, "Register me for the conference"
  end

  test "shows invalid message for an expired invitation token" do
    invitation = Invitation.create!(
      inviter: @inviter,
      conference: @conference,
      first_name: "Guest",
      email: "guest@example.com"
    )
    invitation.update!(expires_at: 1.minute.ago)

    get root_path(invitation_token: invitation.raw_token)

    assert_response :success
    assert_includes response.body, "Invalid invitation token"
    assert_not_includes response.body, "Invite attendee"
    assert_not_includes response.body, "Register me for the conference"
  end
end
