class Course < ApplicationRecord
  belongs_to :seller, class_name: 'User'
  has_many :reviews, dependent: :destroy

  validates :title, :description, :code, :category, presence: true
end
