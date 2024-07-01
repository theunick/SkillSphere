class ApplicationController < ActionController::Base
  before_action :set_current_user
  before_action :set_current_seller

  helper_method :current_user, :current_seller

  private

  def set_current_user
    Rails.logger.debug "Session User ID set to: #{session[:user_id]}"
    @current_user = Account.find_by(uid: session[:user_id])
    path = Rails.application.routes.recognize_path(request.url)
    Rails.logger.debug "User UID: #{@current_user}"

    if path[:controller] == 'courses' && ['new', 'create'].include?(path[:action])
      unless @current_user&.seller?
        flash[:notice] = 'You must be logged in as a seller to create a course.'
        redirect_to root_path
        return
      end
    end
  end

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def set_current_seller
    @current_seller = @current_user if @current_user&.seller?
  end

  def current_seller
    @current_seller&.seller
  end

  def authenticate_seller!
    unless current_seller
      redirect_to root_path, alert: 'You need to sign in as a seller to access this page.'
    end
  end
end
