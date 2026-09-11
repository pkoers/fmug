class AddCompanyNameToUsersAndMagicLinks < ActiveRecord::Migration[8.1]
  def change
    add_column :magic_links, :company_name, :string
    add_column :users, :company_name, :string
  end
end
