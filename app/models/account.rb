class Account < ApplicationRecord
  enum role: { customer: 0, seller: 1, admin: 2 }

  has_many :courses, foreign_key: :seller_id, dependent: :destroy
  has_many :assistance_requests, dependent: :destroy
  has_many :reports, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :purchases, dependent: :destroy
  has_many :bought_courses, through: :purchases, source: :course
  has_one :cart, dependent: :destroy
  after_create :create_cart
  after_initialize :set_default_bio, if: :new_record?

  def self.from_omniauth(auth)
    where(uid: auth.uid, provider: auth.provider).first_or_initialize.tap do |account|
      account.email = auth.info.email
      account.name = auth.info.name
      account.image = auth.info.image
      account.oauth_token = auth.credentials.token
      account.oauth_expires_at = Time.at(auth.credentials.expires_at)
      account.role ||= 'customer'
      account.save!(validate: false)
    end
  end

  def seller?
    self.role == 'seller'
  end

  def create_cart
    Cart.create(account: self)
  end

  def total_spent
    self.purchases.joins(:course).sum('courses.price')
  end

  private

  def set_default_bio
    self.bio ||= 'Adoro SkillSphere'
  end

end
