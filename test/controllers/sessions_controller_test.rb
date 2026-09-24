require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "Google OAuth finds an existing account despite email casing" do
    now = Time.current
    User.insert_all!([ {
      email: "GoogleMember@Example.com",
      first_name: "Google",
      last_name: "Member",
      role: "Member",
      created_at: now,
      updated_at: now
    } ])
    existing_user = User.find_by!(email: "GoogleMember@Example.com")
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "google-member-id",
      info: { email: "googlemember@example.com", first_name: "Google", last_name: "Member" }
    )

    assert_no_difference("User.count") do
      post "/auth/google_oauth2/callback", env: { "omniauth.auth" => auth }
    end

    assert_equal existing_user.id, session[:user_id]
    assert_equal existing_user, Identity.find_by!(provider: "google_oauth2", uid: "google-member-id").user
  end
end
