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

    emit_ci_schedule_form_diagnostics

    click_on "Create Schedule"

    if Rails.env.test? && ENV["CI"].present? && page.has_selector?("#error_explanation", visible: true)
      warn "[CI DIAGNOSTICS] visible validation errors=#{find("#error_explanation", visible: true).text.inspect}"
    end

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

  def emit_ci_schedule_form_diagnostics
    return unless Rails.env.test? && ENV["CI"].present?

    warn "[CI DIAGNOSTICS] @conference.id=#{@conference.id}"
    warn "[CI DIAGNOSTICS] schedule form values=#{schedule_form_values.inspect}"
    warn "[CI DIAGNOSTICS] #schedule_conference_id.options=#{find("#schedule_conference_id").all("option").map { |option| { text: option.text, value: option.value } }.inspect}"
    warn "[CI DIAGNOSTICS] #schedule_conference_id.disabled=#{find("#schedule_conference_id").disabled?}"
    warn "[CI DIAGNOSTICS] page.current_url=#{page.current_url}"
  end

  def schedule_form_values
    {
      conference_id: find_field("Conference").value,
      day: find_field("Conference day").value,
      time: find_field("Start time").value,
      length: find_field("Duration (minutes)").value,
      description: find_field("Session title or description").value
    }
  end

  def sign_in_as(user)
    login_magic_link = user.login_magic_links.create!

    visit login_magic_link_path(login_magic_link.raw_token)
    assert_text "Signed in successfully."
  end
end
