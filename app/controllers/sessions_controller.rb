class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :google_auth

  def google_auth
    user_info = request.env['omniauth.auth']
    Rails.logger.debug "OmniAuth auth hash: #{user_info.inspect}"

    account = Account.from_omniauth(user_info)
    if account.persisted?
      session[:user_id] = account.uid
      redirect_to root_path, notice: 'Logged in successfully'
    else
      Rails.logger.error "Failed to persist account: #{account.errors.full_messages.join(', ')}"
      redirect_to root_path, alert: 'Failed to log in'
    end
  rescue => e
    Rails.logger.error "Google Auth Error: #{e.message}"
    redirect_to root_path, alert: 'Failed to log in'
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path, notice: 'Signed out'
  end
end
