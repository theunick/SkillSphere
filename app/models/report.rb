class Report < ApplicationRecord
  belongs_to :course
  belongs_to :account

  validates :subject, :description, presence: true
end
