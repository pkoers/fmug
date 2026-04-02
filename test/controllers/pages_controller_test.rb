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

  test "shows success message for a valid invitation token when invited email belongs to an existing registered user" do
    user = User.create!(
      email: "guest@example.com",
      first_name: "Existing",
      last_name: "Guest",
      role: "Member"
    )
    Registration.create!(
      user: user,
      conference: @conference,
      attending_physically: true,
      agenda_nothing_to_present: true
    )
    invitation = Invitation.create!(
      inviter: @inviter,
      conference: @conference,
      first_name: "Guest",
      email: "guest@example.com"
    )

    get root_path(invitation_token: invitation.raw_token)

    assert_response :success
    assert_includes response.body, "FMUG Conferences"
    assert_includes response.body, "You are already registered for FMUG 1"
    assert_includes response.body, "known-user-invitation-modal"
    assert_nil invitation.reload.used_at
  end

  test "existing registered user invitation remains valid after landing page visit" do
    user = User.create!(
      email: "guest@example.com",
      first_name: "Existing",
      last_name: "Guest",
      role: "Member"
    )
    Registration.create!(
      user: user,
      conference: @conference,
      attending_physically: true,
      agenda_nothing_to_present: true
    )
    invitation = Invitation.create!(
      inviter: @inviter,
      conference: @conference,
      first_name: "Guest",
      email: "guest@example.com"
    )

    get root_path(invitation_token: invitation.raw_token)
    get root_path(invitation_token: invitation.raw_token)

    assert_response :success
    assert_includes response.body, "known-user-invitation-modal"
    assert_nil invitation.reload.used_at
  end

  test "shows success message for a valid invitation token when invited email belongs to an existing unregistered user" do
    invitation_user = User.create!(
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
    assert_includes response.body, "FMUG Conferences"
    assert_includes response.body, "Welcome back #{invitation_user.first_name}, you are not yet registered for the upcoming FMUG"
    assert_includes response.body, "known-user-invitation-modal"
    assert_not_includes response.body, "Token validated and still valid"
    assert_nil invitation.reload.used_at
  end

  test "existing unregistered user invitation remains valid after landing page visit" do
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
    get root_path(invitation_token: invitation.raw_token)

    assert_response :success
    assert_includes response.body, "known-user-invitation-modal"
    assert_nil invitation.reload.used_at
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
    assert_includes response.body, "FMUG Conferences"
    assert_includes response.body, "new-user-invitation-modal"
    assert_includes response.body, "Complete your FMUG profile"
    assert_includes response.body, "value=\"#{invitation.raw_token}\""
    assert_not_includes response.body, "new-user-invitation-email"
    assert_not_includes response.body, "Invalid invitation token"
    assert_nil invitation.reload.used_at
  end

  test "new user token remains valid after landing page visit" do
    invitation = Invitation.create!(
      inviter: @inviter,
      conference: @conference,
      first_name: "Guest",
      email: "guest@example.com"
    )

    get root_path(invitation_token: invitation.raw_token)
    get root_path(invitation_token: invitation.raw_token)

    assert_response :success
    assert_includes response.body, "new-user-invitation-modal"
    assert_nil invitation.reload.used_at
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

  test "shows the footer privacy link on the landing page" do
    get root_path

    assert_response :success
    assert_includes response.body, "Patrick Koers"
    assert_includes response.body, privacy_path
    assert_includes response.body, "Privacy"
  end

  test "renders the privacy page from markdown content" do
    get privacy_path

    assert_response :success
    assert_includes response.body, "This is a placeholder privacy statement."
  end
end
