class RemoveHiddenFromCourses < ActiveRecord::Migration[6.1]
  def change
    remove_column :courses, :hidden, :boolean
  end
end
