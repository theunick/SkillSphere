class CreateAccounts < ActiveRecord::Migration[6.1]
  def change
    create_table :accounts do |t|
      t.string :email
      t.string :name
      t.string :surname
      t.integer :role

      t.timestamps
    end
  end
end
