class CreateCourses < ActiveRecord::Migration[6.1]
  def change
    create_table :courses do |t|
      t.string :title
      t.string :name
      t.string :price
      t.string :code
      t.string :category
      t.references :seller, null: false, foreign_key: true

      t.timestamps
    end
  end
end
