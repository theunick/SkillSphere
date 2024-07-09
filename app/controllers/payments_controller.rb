class PaymentsController < ApplicationController
  def create
    @cart = current_user.cart
    @amount = @cart.cart_items.sum { |item| (item.course.price.to_f * 100).to_i } # Ensure price is in cents

    # Debugging output
    Rails.logger.debug "Cart: #{@cart.inspect}"
    Rails.logger.debug "Amount: #{@amount}"
    @cart.cart_items.each do |item|
      Rails.logger.debug "Course: #{item.course.title}, Price: #{item.course.price}"
    end

    if @amount < 50
      Rails.logger.error "Total amount must be at least 50 cents"
      flash[:error] = "Total amount must be at least 50 cents"
      redirect_to @cart and return
    end

    begin
      session = Stripe::Checkout::Session.create(
        payment_method_types: ['card'],
        line_items: @cart.cart_items.map { |item|
          {
            price_data: {
              currency: 'eur',
              product_data: {
                name: item.course.title,
              },
              unit_amount: (item.course.price.to_f * 100).to_i, # Convert price to cents
            },
            quantity: 1,
          }
        },
        mode: 'payment',
        success_url: execute_payment_url + '?session_id={CHECKOUT_SESSION_ID}',
        cancel_url: checkout_cancel_url
      )

      Rails.logger.debug "Stripe Session: #{session.inspect}"
      redirect_to session.url, allow_other_host: true
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe Error: #{e.message}"
      flash[:error] = e.message
      redirect_to @cart
    end
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

  def cancel
    redirect_to root_path, alert: "Il pagamento è stato annullato."
  end
end
