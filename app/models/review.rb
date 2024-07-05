class Review < ApplicationRecord
  belongs_to :account
  belongs_to :course

  validates :content, :rating, presence: true
  validates :rating, inclusion: { in: 1..5 }
end
