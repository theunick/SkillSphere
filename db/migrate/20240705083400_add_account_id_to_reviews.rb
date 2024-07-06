class AddAccountIdToReviews < ActiveRecord::Migration[6.1]
  def change
    add_column :reviews, :account_id, :integer
  end
end
