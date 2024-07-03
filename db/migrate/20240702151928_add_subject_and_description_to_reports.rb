class AddSubjectAndDescriptionToReports < ActiveRecord::Migration[6.1]
  def change
    add_column :reports, :description, :text
  end
end
