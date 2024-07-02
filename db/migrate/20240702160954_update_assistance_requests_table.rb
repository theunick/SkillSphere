class UpdateAssistanceRequestsTable < ActiveRecord::Migration[6.1]
  def change
    remove_reference :assistance_requests, :user, foreign_key: true
  end
end
