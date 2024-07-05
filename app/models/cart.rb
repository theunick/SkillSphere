class Cart < ApplicationRecord
  belongs_to :account
  has_many :cart_items, dependent: :destroy
  has_many :courses, through: :cart_items
end