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
    assert_select "input#new-user-invitation-company-name[required][autocomplete='organization']"
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

  test "hides Google login on PROD01 while keeping magic-link login available" do
    with_environment(
      "GOOGLE_CLIENT_ID" => "client-id",
      "GOOGLE_CLIENT_SECRET" => "client-secret",
      "APP_URL" => "fmug.eu"
    ) do
      get root_path
    end

    assert_response :success
    assert_not_includes response.body, "Login with Google"
    assert_select "button#login-magic-link-open", text: "Login"
    assert_not_includes response.body, "Google login is not configured yet."
  end

  test "shows Google login on a non-PROD01 host when configured" do
    with_environment(
      "GOOGLE_CLIENT_ID" => "client-id",
      "GOOGLE_CLIENT_SECRET" => "client-secret",
      "APP_URL" => "https://lab.fmug.eu"
    ) do
      get root_path
    end

    assert_response :success
    assert_includes response.body, "Login with Google"
    assert_not_includes response.body, "Google login is not configured yet."
  end

  test "shows the Google configuration message when credentials are missing" do
    with_environment(
      "GOOGLE_CLIENT_ID" => nil,
      "GOOGLE_CLIENT_SECRET" => nil,
      "APP_URL" => "fmug.eu"
    ) do
      get root_path
    end

    assert_response :success
    assert_not_includes response.body, "Login with Google"
    assert_includes response.body, "Google login is not configured yet."
  end

  test "shows Google login when APP_URL is blank and credentials are configured" do
    with_environment(
      "GOOGLE_CLIENT_ID" => "client-id",
      "GOOGLE_CLIENT_SECRET" => "client-secret",
      "APP_URL" => nil
    ) do
      get root_path
    end

    assert_response :success
    assert_includes response.body, "Login with Google"
  end

  test "recognizes PROD01 host without regard to case" do
    with_environment(
      "GOOGLE_CLIENT_ID" => "client-id",
      "GOOGLE_CLIENT_SECRET" => "client-secret",
      "APP_URL" => "FMUG.EU"
    ) do
      get root_path
    end

    assert_response :success
    assert_not_includes response.body, "Login with Google"
  end

  test "keeps logged-in landing controls unchanged" do
    user = User.create!(
      email: "member@example.com",
      first_name: "Member",
      last_name: "User",
      role: "Member"
    )
    login_magic_link = user.login_magic_links.create!

    with_environment(
      "GOOGLE_CLIENT_ID" => "client-id",
      "GOOGLE_CLIENT_SECRET" => "client-secret",
      "APP_URL" => "https://lab.fmug.eu"
    ) do
      get login_magic_link_path(login_magic_link.raw_token)
      get root_path
    end

    assert_response :success
    assert_includes response.body, "Signed in as #{user.email}"
    assert_includes response.body, "Logout"
    assert_select "button#login-magic-link-open", count: 0
    assert_not_includes response.body, "Login with Google"
  end

  test "renders the privacy page from markdown content" do
    get privacy_path

    assert_response :success
    assert_includes response.body, "Privacy Statement (DRAFT)"
    assert_includes response.body, "chair@fmug.eu"
  end

  test "renders leadership profile names and cropped photos on the landing page" do
    profile = LeadershipProfile.create!(chair_name: "Ada Chair", vice_chair_name: "Grace Vice")
    profile.chair_photo.attach(io: StringIO.new("chair"), filename: "chair.png", content_type: "image/png")
    profile.vice_chair_photo.attach(io: StringIO.new("vice-chair"), filename: "vice-chair.png", content_type: "image/png")

    get root_path

    assert_response :success
    assert_operator response.body.index("Ada Chair"), :<, response.body.index("Grace Vice")
    assert_select "sl-avatar[style*='9rem'][image*='representations']", count: 2
  end

  test "renders leadership fallbacks when profile data is missing or blank" do
    get root_path

    assert_response :success
    assert_includes response.body, ERB::Util.html_escape(LeadershipProfilesHelper::CHAIR_PLACEHOLDER_IMAGE)
    assert_includes response.body, ERB::Util.html_escape(LeadershipProfilesHelper::VICE_CHAIR_PLACEHOLDER_IMAGE)
    assert_includes response.body, ">Chair<"
    assert_includes response.body, ">Vice-Chair<"

    LeadershipProfile.create!(chair_name: "   ", vice_chair_name: "")
    get root_path

    assert_includes response.body, ">Chair<"
    assert_includes response.body, ">Vice-Chair<"
  end

  private

  def with_environment(variables)
    previous_values = variables.keys.to_h { |key| [ key, ENV[key] ] }
    variables.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }

    yield
  ensure
    previous_values.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end
end
