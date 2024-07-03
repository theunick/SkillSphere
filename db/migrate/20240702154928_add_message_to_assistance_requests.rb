class AddMessageToAssistanceRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :assistance_requests, :message, :text
  end
end
