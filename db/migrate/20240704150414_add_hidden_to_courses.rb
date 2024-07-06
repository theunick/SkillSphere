class AddHiddenToCourses < ActiveRecord::Migration[6.1]
  def change
    add_column :courses, :hidden, :boolean, default: false
  end
end
