class ApplicationController < ActionController::Base
  before_action :set_current_user

  helper_method :current_user, :current_seller

  private

  def set_current_user
    Rails.logger.debug "Session User ID set to: #{session[:user_id]}"
    @current_user = Account.find_by(uid: session[:user_id])
    Rails.logger.debug "User UID: #{@current_user}"
  end

  def current_user
    @current_user
  end

  def set_current_seller
    @current_seller = @current_user if @current_user&.seller?
  end

  def current_seller
    @current_seller
  end

  def authenticate_seller!
    unless current_seller
      redirect_to root_path, alert: 'You need to sign in as a seller to access this page.'
    end
  end
end
