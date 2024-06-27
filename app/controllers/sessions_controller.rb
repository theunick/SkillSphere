class SessionsController < ApplicationController
  def create
    user_info = request.env['omniauth.auth']
    session[:google_drive_credentials] = user_info['credentials']
    redirect_to root_path, notice: 'Signed in with Google'
  end

  def destroy
    session[:google_drive_credentials] = nil
    redirect_to root_path, notice: 'Signed out'
  end
end

