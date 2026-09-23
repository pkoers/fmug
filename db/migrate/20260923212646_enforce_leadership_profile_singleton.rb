class EnforceLeadershipProfileSingleton < ActiveRecord::Migration[8.1]
  def up
    execute "LOCK TABLE leadership_profiles IN ACCESS EXCLUSIVE MODE"

    if select_value("SELECT COUNT(*) FROM leadership_profiles").to_i > 1
      raise ActiveRecord::IrreversibleMigration, "Multiple leadership profiles exist. Choose a canonical record before enforcing the singleton."
    end

    add_column :leadership_profiles, :singleton_key, :integer, null: false, default: 1
    add_index :leadership_profiles, :singleton_key, unique: true
    add_check_constraint :leadership_profiles, "singleton_key = 1", name: "leadership_profiles_singleton_key"
  end

  def down
    remove_check_constraint :leadership_profiles, name: "leadership_profiles_singleton_key"
    remove_index :leadership_profiles, :singleton_key
    remove_column :leadership_profiles, :singleton_key
  end
end
