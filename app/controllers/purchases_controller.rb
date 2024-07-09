class PurchasesController < ApplicationController
    before_action :authenticate_user!
  
    def create
      @course = Course.find(params[:id])
      
      if current_user.courses.include?(@course)
        redirect_to courses_path, alert: "Hai già acquistato questo corso."
      else
        @purchase = current_user.purchases.build(course: @course)
        
        if @purchase.save
          redirect_to @course, notice: "Corso acquistato con successo."
        else
          redirect_to @course, alert: "Errore durante l'acquisto del corso."
        end
      end
    end
  end
  