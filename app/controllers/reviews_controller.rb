class ReviewsController < ApplicationController
    before_action :set_course
    before_action :authenticate_user!
  
    def create
      @review = @course.reviews.new(review_params)
      @review.account = current_user
  
      if @review.save
        redirect_to course_path(@course), notice: 'Recensione aggiunta con successo.'
      else
        redirect_to course_path(@course), alert: 'Errore nell\'aggiunta della recensione.'
      end
    end
  
    private
  
    def set_course
      @course = Course.find(params[:course_id])
    end
  
    def review_params
      params.require(:review).permit(:content, :rating)
    end
  end
  