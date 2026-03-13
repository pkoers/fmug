class CreateLoginMagicLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :login_magic_links do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at

      t.timestamps
    end

    add_index :login_magic_links, :token_digest, unique: true
  end
end
