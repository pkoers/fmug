class CreateInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :invitations do |t|
      t.references :conference, null: false, foreign_key: true
      t.references :inviter, null: false, foreign_key: { to_table: :users }
      t.string :email, null: false
      t.string :first_name, null: false
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at

      t.timestamps
    end

    add_index :invitations, :token_digest, unique: true
    add_index :invitations, :email
  end
end
