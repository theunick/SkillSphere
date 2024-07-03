class AddAccountIdToAssistanceRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :assistance_requests, :account_id, :integer
  end
end
