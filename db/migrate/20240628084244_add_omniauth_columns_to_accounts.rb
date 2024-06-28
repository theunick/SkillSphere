class AddOmniauthColumnsToAccounts < ActiveRecord::Migration[6.1]
  def change
    add_column :accounts, :provider, :string
    add_column :accounts, :image, :string
    add_column :accounts, :oauth_token, :string
    add_column :accounts, :oauth_expires_at, :datetime
  end
end
