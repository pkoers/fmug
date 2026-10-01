require "test_helper"

class PagesControllerAttendanceTest < ActionController::TestCase
  tests PagesController

  test "logged-in member sees awaiting travel approval as their current attendance" do
    user = User.create!(
      email: "awaiting@example.com",
      first_name: "Awaiting",
      last_name: "Member",
      role: "Member"
    )
    Registration.create!(
      user: user,
      conference: conferences(:one),
      attendance_status: "awaiting_travel_approval",
      agenda_nothing_to_present: true
    )
    session[:user_id] = user.id

    get :landing

    assert_response :success
    assert_includes response.body, "Current attendance: <strong>Awaiting Travel Approval</strong>"
  end
end
