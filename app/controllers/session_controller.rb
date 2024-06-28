# app/controllers/sessions_controller.rb
class SessionController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :google_auth

  def create
  
    auth = request.env['omniauth.auth']
    user = Account.from_omniauth(auth)
    session[:user_id] = user.id
      redirect_to root_path, notice: 'Logged in successfully'

  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: 'Signed out'
  end
end
