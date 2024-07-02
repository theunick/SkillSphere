class AddGoogleDriveFileIdsToCourses < ActiveRecord::Migration[6.1]
  def change
    add_column :courses, :google_drive_file_ids, :json
  end
end
