# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
    helper_method :current_seller
  
    private
  
    def current_seller
      # Implementazione basilare che puoi sostituire in seguito
      # Simula un utente seller attualmente autenticato
      @current_seller ||= Seller.first # Sostituisci con la logica di autenticazione reale
    end
  
    def authenticate_seller!
      # Implementazione basilare che puoi sostituire in seguito
      unless current_seller
        redirect_to new_session_path, alert: 'You need to sign in as a seller to access this page.'
      end
    end
  
    def authorize_seller!
      # Implementazione basilare che puoi sostituire in seguito
      unless @course.seller == current_seller
        redirect_to courses_path, alert: 'You are not authorized to edit or delete this course.'
      end
    end
  end
  