require "test_helper"
require Rails.root.join("db/migrate/20261001090000_add_attendance_status_to_registrations")

class AddAttendanceStatusToRegistrationsTest < ActiveSupport::TestCase
  test "rollback stops while a registration awaits travel approval" do
    user = User.create!(email: "awaiting-rollback@example.com", first_name: "Awaiting", last_name: "Rollback", role: "Member")
    registration = Registration.create!(
      user: user,
      conference: conferences(:one),
      attendance_status: "awaiting_travel_approval",
      agenda_nothing_to_present: true
    )

    error = assert_raises(ActiveRecord::IrreversibleMigration) do
      AddAttendanceStatusToRegistrations.new.down
    end

    assert_includes error.message, "Resolve those registrations first"
    assert_equal "awaiting_travel_approval", registration.reload.attendance_status
  end
end
