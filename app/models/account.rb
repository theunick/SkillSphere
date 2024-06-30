class Account < ApplicationRecord
    enum role: { customer: 0, seller: 1, admin: 2 }
  
    def self.from_omniauth(auth)
      Rails.logger.debug "Auth data received: #{auth.inspect}"
      account = where(uid: auth.uid, provider: auth.provider).first_or_initialize
  
      account.email = auth.info.email
      account.name = auth.info.name
      account.surname = auth.info.last_name || ""
      account.image = auth.info.image
      account.oauth_token = auth.credentials.token
      account.oauth_expires_at = Time.at(auth.credentials.expires_at)
      account.role ||= 'customer'
  
      if account.save
        Rails.logger.debug "Account saved: #{account.inspect}"
      else
        Rails.logger.error "Failed to save account: #{account.errors.full_messages.join(', ')}"
      end
  
      account
    end
  end
  