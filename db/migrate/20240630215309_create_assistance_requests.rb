class CreateAssistanceRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :assistance_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.text :description
      t.string :status

      t.timestamps
    end
  end
end
