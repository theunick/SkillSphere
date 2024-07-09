class Course < ApplicationRecord
  is_impressionable

  belongs_to :seller, class_name: 'Account', foreign_key: 'seller_id'
  has_many :reviews, dependent: :destroy
  has_many :reports, dependent: :destroy
  has_many :purchases, dependent: :destroy
  has_many :buyers, through: :purchases, source: :account
  has_many :cart_items

  validates :title, :description, :category, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :visible, -> { where(hidden: false) }

  before_validation :set_default_price
  after_initialize :set_default_google_drive_file_ids, if: :new_record?

  def set_default_google_drive_file_ids
    self.google_drive_file_ids ||= '[]'
  end

  def total_earnings
    (purchases.count * price.to_f).round(2)
  end

  def purchases_count
    purchases.count
  end

  def views_count
    impressions.count
  end

  private

  def set_default_price
    self.price ||= 0.0
  end
end
