class AddOauthColumnsToAccounts < ActiveRecord::Migration[6.1]
  def change
    add_column :accounts, :oauth_token, :string
    add_column :accounts, :oauth_expires_at, :datetime
  end
end
