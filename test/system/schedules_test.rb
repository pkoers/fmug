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

    find_field("Conference").find("option[value='#{@conference.id}']").select_option
    assert_equal @conference.id.to_s, find("#schedule_conference_id").value
    fill_in "Conference day", with: 1
    page.execute_script(<<~JAVASCRIPT)
      const timeField = document.getElementById("schedule_time");
      timeField.value = "09:30";
      timeField.dispatchEvent(new Event("input", { bubbles: true }));
      timeField.dispatchEvent(new Event("change", { bubbles: true }));
    JAVASCRIPT
    assert_equal "09:30", find("#schedule_time").value
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
