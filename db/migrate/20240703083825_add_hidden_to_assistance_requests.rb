class AddHiddenToAssistanceRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :assistance_requests, :hidden, :boolean, default: false
  end
end
