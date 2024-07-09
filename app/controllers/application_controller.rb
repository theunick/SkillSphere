class ApplicationController < ActionController::Base
  before_action :set_current_user
  before_action :authenticate_user!, only: [:new, :create]

  helper_method :current_user, :current_seller

  def log_in(user)
    session[:user_id] = user.id
  end

  private

  def set_current_user
    @current_user = Account.find_by(uid: session[:user_id])
  end

  def current_user
    @current_user 
  end

  def current_seller
    current_user if current_user&.seller?
  end

  def authenticate_seller!
    unless current_seller
      redirect_to root_path, alert: 'You need to sign in as a seller to access this page.'
    end
  end

  def authenticate_user!
    unless current_user
      redirect_to new_session_path, alert: "Devi essere loggato per accedere a questa pagina."
    end
  end
  
end
