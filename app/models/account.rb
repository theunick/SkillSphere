class Account < ApplicationRecord
  enum role: { customer: 0, seller: 1, admin: 2 }

  has_many :courses, foreign_key: :seller_id
  has_many :assistance_requests

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  def self.from_omniauth(auth)
    where(uid: auth.uid, provider: auth.provider).first_or_initialize.tap do |account|
      account.email = auth.info.email
      account.name = auth.info.name
      account.image = auth.info.image
      account.oauth_token = auth.credentials.token
      account.oauth_expires_at = Time.at(auth.credentials.expires_at)
      account.role ||= 'seller'
      account.save!
    end
  end

  def seller?
    self.role == 'seller'
  end
end
