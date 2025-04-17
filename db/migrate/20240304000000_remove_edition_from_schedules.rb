class RemoveEditionFromSchedules < ActiveRecord::Migration[8.0]
  def change
    remove_column :schedules, :edition, :integer
  end
end
