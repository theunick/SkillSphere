class User < ApplicationRecord
  has_one :cart, dependent: :destroy
  has_many :purchases, dependent: :destroy
  has_many :bought_courses, through: :purchases, source: :course  # Associazione per i corsi acquistati
  
  has_many :courses, foreign_key: :seller_id

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

  def seller?
    # Definisci la logica per determinare se l'utente è un venditore
    self.role == 'seller'
  end
end
