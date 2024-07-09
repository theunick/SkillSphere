class Review < ApplicationRecord
  belongs_to :account
  belongs_to :course
  has_many :responses, dependent: :destroy

  validates :content, :rating, presence: true
  validates :rating, inclusion: { in: 1..5 }
end
