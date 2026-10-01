require "test_helper"
require Rails.root.join("db/migrate/20261001090000_add_attendance_status_to_registrations")

class AddAttendanceStatusToRegistrationsTest < ActiveSupport::TestCase
  test "rollback and migration preserve multiple losslessly representable registrations" do
    physical_registration = create_registration("physical", "physical-rollback@example.com")
    online_registration = create_registration("online", "online-rollback@example.com")
    migration = AddAttendanceStatusToRegistrations.new

    migration.down
    Registration.reset_column_information

    assert_not Registration.connection.column_exists?(:registrations, :attendance_status)
    assert_equal true, Registration.connection.select_value("SELECT attending_physically FROM registrations WHERE id = #{physical_registration.id}")
    assert_equal false, Registration.connection.select_value("SELECT attending_physically FROM registrations WHERE id = #{online_registration.id}")

    migration.up
    Registration.reset_column_information

    assert_equal "physical", physical_registration.reload.attendance_status
    assert_equal "online", online_registration.reload.attendance_status
    assert physical_registration.attending_physically?
    assert_not online_registration.attending_physically?
  ensure
    migration&.up unless Registration.connection.column_exists?(:registrations, :attendance_status)
    Registration.reset_column_information
  end

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

    assert_includes error.message, "cannot be represented losslessly"
    assert_equal "awaiting_travel_approval", registration.reload.attendance_status
  end

  test "rollback stops when physical attendance disagrees with the legacy flag" do
    assert_rollback_stops_for_mismatched_registration("physical", false)
  end

  test "rollback stops when online attendance disagrees with the legacy flag" do
    assert_rollback_stops_for_mismatched_registration("online", true)
  end

  private

  def assert_rollback_stops_for_mismatched_registration(status, attending_physically)
    user = User.create!(
      email: "#{status}-#{attending_physically}-rollback@example.com",
      first_name: "Mismatched",
      last_name: "Rollback",
      role: "Member"
    )
    registration = Registration.create!(
      user: user,
      conference: conferences(:one),
      attendance_status: status,
      agenda_nothing_to_present: true
    )
    migration = AddAttendanceStatusToRegistrations.new

    remove_compatibility_constraint
    registration.update_columns(attending_physically: attending_physically)

    error = assert_raises(ActiveRecord::IrreversibleMigration) { migration.down }
    assert_includes error.message, "cannot be represented losslessly"
    assert Registration.column_names.include?("attendance_status")
    assert_equal attending_physically, registration.reload.attending_physically?
  ensure
    registration&.update_columns(attending_physically: status == "physical")
    add_compatibility_constraint unless compatibility_constraint_exists?
  end

  def create_registration(status, email)
    user = User.create!(email:, first_name: status.capitalize, last_name: "Rollback", role: "Member")
    Registration.create!(
      user: user,
      conference: conferences(:one),
      attendance_status: status,
      agenda_nothing_to_present: true
    )
  end

  def remove_compatibility_constraint
    Registration.connection.remove_check_constraint(
      :registrations,
      name: AddAttendanceStatusToRegistrations::COMPATIBILITY_CHECK_CONSTRAINT_NAME
    )
  end

  def add_compatibility_constraint
    migration = AddAttendanceStatusToRegistrations.new
    Registration.connection.add_check_constraint(
      :registrations,
      migration.send(:compatibility_constraint),
      name: AddAttendanceStatusToRegistrations::COMPATIBILITY_CHECK_CONSTRAINT_NAME
    )
  end

  def compatibility_constraint_exists?
    Registration.connection.check_constraints(:registrations).any? do |constraint|
      constraint.name == AddAttendanceStatusToRegistrations::COMPATIBILITY_CHECK_CONSTRAINT_NAME
    end
  end
end
