class CreateAccounts < ActiveRecord::Migration[6.1]
  def change
    create_table :accounts do |t|
      t.string :uid
      t.string :provider
      t.string :email
      t.string :name
      t.string :surname
      t.string :image
      t.string :oauth_token
      t.datetime :oauth_expires_at
      t.integer :role

      t.timestamps
    end
  end
end
