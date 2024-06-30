# app/models/user.rb
class User < ApplicationRecord

  devise :database_authenticatable, :registerable,
  :recoverable, :rememberable, :validatable
  
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.name = auth.info.name
      user.image = auth.info.image
      user.oauth_token = auth.credentials.token
      user.oauth_expires_at = Time.at(auth.credentials.expires_at)
    end
  end
end
