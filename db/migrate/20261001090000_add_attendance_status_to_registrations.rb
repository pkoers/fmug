class AddAttendanceStatusToRegistrations < ActiveRecord::Migration[8.1]
  CHECK_CONSTRAINT_NAME = "registrations_attendance_status_check"
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
      name: CHECK_CONSTRAINT_NAME
  end

  def down
    if select_value(<<~SQL.squish)
      SELECT EXISTS (
        SELECT 1 FROM registrations
        WHERE attendance_status = '#{AWAITING_TRAVEL_APPROVAL}'
      )
    SQL
      raise ActiveRecord::IrreversibleMigration,
        "Cannot remove attendance_status while registrations await travel approval. Resolve those registrations first."
    end

    remove_check_constraint :registrations, name: CHECK_CONSTRAINT_NAME
    remove_column :registrations, :attendance_status
  end
end
