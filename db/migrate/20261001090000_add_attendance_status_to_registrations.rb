class AddAttendanceStatusToRegistrations < ActiveRecord::Migration[8.1]
  ATTENDANCE_STATUS_CHECK_CONSTRAINT_NAME = "registrations_attendance_status_check"
  COMPATIBILITY_CHECK_CONSTRAINT_NAME = "registrations_attendance_status_compatibility_check"
  AWAITING_TRAVEL_APPROVAL = "awaiting_travel_approval"

  def up
    add_column :registrations, :attendance_status, :string

    execute <<~SQL.squish
      UPDATE registrations
      SET attendance_status = CASE
        WHEN attending_physically THEN 'physical'
        ELSE 'online'
      END
      WHERE attendance_status IS NULL
    SQL

    change_column_null :registrations, :attendance_status, false
    add_check_constraint :registrations,
      "attendance_status IN ('physical', 'online', '#{AWAITING_TRAVEL_APPROVAL}')",
      name: ATTENDANCE_STATUS_CHECK_CONSTRAINT_NAME
    add_check_constraint :registrations,
      compatibility_constraint,
      name: COMPATIBILITY_CHECK_CONSTRAINT_NAME
  end

  def down
    if select_value(<<~SQL.squish)
      SELECT EXISTS (
        SELECT 1 FROM registrations
        WHERE (#{losslessly_rollback_safe_constraint}) IS NOT TRUE
      )
    SQL
      raise ActiveRecord::IrreversibleMigration,
        "Cannot remove attendance_status while registrations cannot be represented losslessly by the legacy attendance flag."
    end

    remove_check_constraint :registrations, name: COMPATIBILITY_CHECK_CONSTRAINT_NAME
    remove_check_constraint :registrations, name: ATTENDANCE_STATUS_CHECK_CONSTRAINT_NAME
    remove_column :registrations, :attendance_status
  end

  private

  def compatibility_constraint
    <<~SQL.squish
      (attendance_status = 'physical' AND attending_physically IS TRUE)
      OR (attendance_status IN ('online', '#{AWAITING_TRAVEL_APPROVAL}') AND attending_physically IS FALSE)
    SQL
  end

  def losslessly_rollback_safe_constraint
    <<~SQL.squish
      (attendance_status = 'physical' AND attending_physically IS TRUE)
      OR (attendance_status = 'online' AND attending_physically IS FALSE)
    SQL
  end
end
