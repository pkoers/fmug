require "application_system_test_case"

class SchedulesTest < ApplicationSystemTestCase
  setup do
    @conference = conferences(:one)
    @admin = User.create!(
      email: "schedule-admin-system@example.com",
      first_name: "Schedule",
      last_name: "Admin",
      role: "Member",
      admin: true
    )
  end

  test "admin can manage schedule items" do
    sign_in_as(@admin)

    visit schedules_url
    assert_selector "h1", text: "Manage schedules"

    click_on "New schedule item"

    select @conference.edition.to_s, from: "Conference"
    fill_in "Conference day", with: 1
    fill_in "Start time", with: "09:30"
    fill_in "Duration (minutes)", with: 45
    fill_in "Session title or description", with: "System test opening session"
    click_on "Create Schedule"

    assert_text "Schedule was successfully created"
    assert_text "System test opening session"

    click_on "Edit this schedule", match: :first

    fill_in "Session title or description", with: "System test updated session"
    fill_in "Duration (minutes)", with: 60
    click_on "Update Schedule"

    assert_text "Schedule was successfully updated"
    assert_text "System test updated session"
    assert_text "60 minutes"

    click_on "Delete this schedule", match: :first

    assert_text "Schedule was successfully destroyed"
    assert_no_text "System test updated session"
  end

  test "public agenda shows current schedule items" do
    @conference.schedules.create!(
      day: 2,
      time: "14:15",
      length: 30,
      description: "Public agenda system session"
    )

    visit agenda_url

    assert_text "Day 2"
    assert_text "Public agenda system session"
  end

  private

  def sign_in_as(user)
    login_magic_link = user.login_magic_links.create!

    visit login_magic_link_path(login_magic_link.raw_token)
    assert_text "Signed in successfully."
  end
end
