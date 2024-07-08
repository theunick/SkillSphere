class PaymentsController < ApplicationController
    before_action :authenticate_user!
  
    def new
      @course = Course.find(params[:id])
      @stripe_publishable_key = ENV['STRIPE_PUBLISHABLE_KEY']
    end
  
    def create
      @course = Course.find(params[:course_id])
      token = params[:stripeToken]
  
      begin
        charge = Stripe::Charge.create(
          amount: (@course.price * 100).to_i, # Stripe amount is in cents
          currency: 'usd',
          description: @course.title,
          source: token,
          metadata: { user_id: current_user.id, course_id: @course.id }
        )
  
        # Se il pagamento è andato a buon fine, salva l'acquisto nel database
        current_user.purchases.create(course: @course)
  
        redirect_to @course, notice: 'Pagamento effettuato con successo. Hai acquistato il corso.'
      rescue Stripe::CardError => e
        flash[:alert] = e.message
        render :new
      end
    end
  end  