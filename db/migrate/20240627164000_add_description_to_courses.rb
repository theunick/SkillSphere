class AddDescriptionToCourses < ActiveRecord::Migration[6.1]
  def change
    add_column :courses, :description, :string
  end
end
