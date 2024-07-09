class AddNameAndPriceToCourses < ActiveRecord::Migration[6.1]
  def change
    add_column :courses, :name, :string
    unless column_exists?(:courses, :price)
      add_column :courses, :price, :decimal
    end
  end
end
