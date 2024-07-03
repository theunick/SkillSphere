class AddResponseToAssistanceRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :assistance_requests, :response, :text
  end
end
