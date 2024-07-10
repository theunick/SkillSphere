class Response < ApplicationRecord
  belongs_to :review
  belongs_to :account

  validates :content, presence: true
end
