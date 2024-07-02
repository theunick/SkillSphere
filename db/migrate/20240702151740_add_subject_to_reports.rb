class AddSubjectToReports < ActiveRecord::Migration[6.1]
  def change
    add_column :reports, :subject, :string
  end
end
