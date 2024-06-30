class Report < ApplicationRecord
  belongs_to :account
  belongs_to :course

  validates :message, presence: true
end
