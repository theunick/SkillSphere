class Account < ApplicationRecord
    enum role: { customer: 0, seller: 1, admin: 2 }
  
    validates :uid, presence: true, uniqueness: true
    validates :email, presence: true, uniqueness: true
    validates :name, presence: true
    validates :surname, presence: true
    validates :role, presence: true, inclusion: { in: roles.keys }
  
    def self.from_omniauth(auth)
      Rails.logger.debug "Auth data received: #{auth.inspect}"  # Aggiungi questo per vedere i dati ricevuti
      where(uid: auth.uid, provider: auth.provider).first_or_create do |account|
        account.uid = auth.uid
        account.provider = auth.provider
        account.name = auth.info.name
        account.surname = auth.info.last_name # Assuming you have surname from auth.info
        account.email = auth.info.email
        account.role ||= 'customer' # or any default role you want to set
      end
    end
  end
  