class FixForeignKeyForCourses < ActiveRecord::Migration[6.1]
  def change
    remove_foreign_key :courses, column: :seller_id
    add_foreign_key :courses, :accounts, column: :seller_id
  end
end
