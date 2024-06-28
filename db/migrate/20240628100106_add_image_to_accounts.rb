class AddImageToAccounts < ActiveRecord::Migration[6.1]
  def change
    add_column :accounts, :image, :string
  end
end
