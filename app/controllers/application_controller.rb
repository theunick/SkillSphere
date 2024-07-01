class ApplicationController < ActionController::Base
  before_action :set_current_user
  before_action :authenticate_seller!, only: [:new, :create]

  helper_method :current_user, :current_seller

  private

  def set_current_user
    @current_user = Account.find_by(uid: session[:user_id])
    redirect_to root_path, alert: 'You must be logged in.' unless @current_user
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
end
