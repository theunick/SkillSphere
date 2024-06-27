class CreateAssistances < ActiveRecord::Migration[6.1]
  def change
    create_table :assistances do |t|
      t.text :message
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
