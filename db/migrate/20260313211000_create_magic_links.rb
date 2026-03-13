class CreateMagicLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :magic_links do |t|
      t.references :invitation, null: false, foreign_key: true
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at

      t.timestamps
    end

    add_index :magic_links, :token_digest, unique: true
  end
end
