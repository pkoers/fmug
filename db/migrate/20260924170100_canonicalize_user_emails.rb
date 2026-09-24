class CanonicalizeUserEmails < ActiveRecord::Migration[8.1]
  def up
    duplicates = select_values(<<~SQL.squish)
      SELECT lower(btrim(email))
      FROM users
      GROUP BY lower(btrim(email))
      HAVING COUNT(*) > 1
    SQL

    if duplicates.any?
      raise ActiveRecord::MigrationError,
        "Cannot canonicalize user emails because case-insensitive duplicates exist: #{duplicates.join(', ')}"
    end

    execute "UPDATE users SET email = lower(btrim(email)) WHERE email <> lower(btrim(email))"
    add_index :users, "lower(email)", unique: true, name: "index_users_on_normalized_email"
  end

  def down
    remove_index :users, name: "index_users_on_normalized_email"
  end
end
