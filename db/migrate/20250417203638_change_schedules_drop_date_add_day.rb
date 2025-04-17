class ChangeSchedulesDropDateAddDay < ActiveRecord::Migration[8.0]
  def change
      # remove the old `date` column
      remove_column :schedules, :date, :date
      # add the new `day` column (integer)
      add_column    :schedules, :day, :integer
  end
end
