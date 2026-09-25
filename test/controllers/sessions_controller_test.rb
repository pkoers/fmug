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

    with_environment("APP_URL" => "fmug.eu") do
      assert_no_difference("User.count") do
        post "/auth/google_oauth2/callback", env: { "omniauth.auth" => auth }
      end
    end

    assert_equal existing_user.id, session[:user_id]
    assert_equal existing_user, Identity.find_by!(provider: "google_oauth2", uid: "google-member-id").user
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
