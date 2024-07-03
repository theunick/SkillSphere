class Course < ApplicationRecord
  belongs_to :seller, class_name: 'Account', foreign_key: 'seller_id'
  has_many :reviews, dependent: :destroy
  has_many :reports, dependent: :destroy

  validates :title, :description, :code, :category, presence: true

  after_initialize :set_default_google_drive_file_ids, if: :new_record?

  def set_default_google_drive_file_ids
    self.google_drive_file_ids ||= '[]'
  end
  
end
