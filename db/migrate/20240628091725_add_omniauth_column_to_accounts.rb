class AddOmniauthColumnToAccounts < ActiveRecord::Migration[6.1]
  def change
    add_column :accounts, :provider, :string
  end
end
