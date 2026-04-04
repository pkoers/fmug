require "application_system_test_case"

class ConferencesTest < ApplicationSystemTestCase
  setup do
    @conference = conferences(:one)
    @admin = User.create!(
      email: "admin-system@example.com",
      first_name: "Admin",
      last_name: "System",
      role: "Member",
      admin: true
    )
  end

  test "visiting the index" do
    sign_in_as(@admin)

    visit conferences_url
    assert_selector "h1", text: "Manage conferences"
    assert_link "Home", href: root_path
  end

  test "should create conference" do
    sign_in_as(@admin)

    visit conferences_url
    click_on "New conference"

    fill_in "Edition", with: 3
    fill_in "Start date", with: Date.current + 60.days
    fill_in "End date", with: Date.current + 62.days
    fill_in "Host", with: "System Test Host"
    fill_in "Location", with: "System Test Location"
    click_on "Create Conference"

    assert_text "Conference was successfully created"
    assert_selector "h1", text: "Conference details"
  end

  test "should update Conference" do
    sign_in_as(@admin)

    visit conference_url(@conference)
    click_on "Edit this conference", match: :first

    fill_in "Host", with: "Updated Host"
    click_on "Update Conference"

    assert_text "Conference was successfully updated"
    assert_text "Updated Host"
  end

  test "should destroy Conference" do
    sign_in_as(@admin)

    visit conference_url(@conference)
    click_on "Delete this conference", match: :first

    assert_text "Conference was successfully destroyed"
  end

  private

  def sign_in_as(user)
    login_magic_link = user.login_magic_links.create!

    visit login_magic_link_path(login_magic_link.raw_token)
    assert_text "Signed in successfully."
  end
end
