class PaymentsController < ApplicationController
    def create
      @cart = current_user.cart
      @amount = (@cart.cart_items.sum { |item| item.course.price } * 100).to_i # Amount in cents
  
      session = Stripe::Checkout::Session.create(
        payment_method_types: ['card'],
        line_items: @cart.cart_items.map { |item|
          {
            price_data: {
              currency: 'eur',
              product_data: {
                name: item.course.title,
              },
              unit_amount: (item.course.price * 100).to_i,
            },
            quantity: 1,
          }
        },
        mode: 'payment',
        success_url: execute_payment_url + '?session_id={CHECKOUT_SESSION_ID}',
        cancel_url: root_url
      )
  
      redirect_to session.url, allow_other_host: true
    rescue Stripe::StripeError => e
      flash[:error] = e.message
      redirect_to @cart
    end
  
    def execute
      session = Stripe::Checkout::Session.retrieve(params[:session_id])
      if session.payment_status == 'paid'
        @cart = current_user.cart
        @cart.cart_items.each do |item|
          Purchase.create(account: current_user, course: item.course)
        end
        @cart.cart_items.destroy_all
  
        redirect_to root_path, notice: "Il pagamento è stato completato con successo."
      else
        redirect_to root_path, alert: "Errore durante il pagamento."
      end
    end
  end
  