class ResponsesController < ApplicationController
    before_action :set_review
  
    def create
      @response = @review.responses.new(response_params)
      @response.account = current_user
  
      if @response.save
        redirect_to course_path(@review.course), notice: 'Risposta aggiunta con successo.'
      else
        redirect_to course_path(@review.course), alert: 'Errore nell\'aggiunta della risposta.'
      end
    end
  
    private
  
    def set_review
      @review = Review.find(params[:review_id])
    end
  
    def response_params
      params.require(:response).permit(:content)
    end
  end
  