class CreateReports < ActiveRecord::Migration[6.1]
  def change
    create_table :reports do |t|
      t.references :account, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.string :message

      t.timestamps
    end
  end
end
