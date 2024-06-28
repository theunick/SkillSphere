class ChangeUidToStringInAccounts < ActiveRecord::Migration[6.1]
  def up
    change_column :accounts, :uid, :string
  end

  def down
    change_column :accounts, :uid, :integer
  end
end
