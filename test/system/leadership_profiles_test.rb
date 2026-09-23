require "application_system_test_case"

class LeadershipProfilesTest < ApplicationSystemTestCase
  setup do
    LeadershipProfile.destroy_all
    @admin = User.create!(email: "leadership-admin@example.com", first_name: "Leadership", last_name: "Admin", role: "Member", admin: true)
    @profile = LeadershipProfile.create!
    @profile.chair_photo.attach(
      io: File.open(Rails.root.join("app/assets/images/fmug-400dpiLogo.jpeg")),
      filename: "original.jpeg",
      content_type: "image/jpeg"
    )
  end

  test "admin can manage Chair profile from the Members submenu" do
    sign_in_as(@admin)

    visit users_url
    find("summary[aria-label='Manage Chair and Vice-Chair profiles']").click
    fill_in "leadership_profile_chair_name", with: "Ada Chair"
    attach_file "leadership_profile_chair_photo", Rails.root.join("app/assets/images/fmug-400dpiLogo.jpeg")
    click_on "Save Chair profile"

    assert_text "Leadership profiles were updated."

    find("summary[aria-label='Manage Chair and Vice-Chair profiles']").click
    assert_field "leadership_profile_chair_name", with: "Ada Chair"
    assert_button "Remove Chair photo"
    accept_confirm { click_on "Remove Chair photo" }

    assert_text "Chair photo was removed."
    find("summary[aria-label='Manage Chair and Vice-Chair profiles']").click
    assert_no_button "Remove Chair photo"
  end

  private

  def sign_in_as(user)
    login_magic_link = user.login_magic_links.create!

    visit login_magic_link_path(login_magic_link.raw_token)
    assert_text "Signed in successfully."
  end
end
