# app/controllers/carts_controller.rb
class CartsController < ApplicationController
  before_action :set_cart, only: [:show, :add_course, :remove_course, :purchase]

  def show
  end

  def add_course
    course = Course.find(params[:course_id])
    if @cart.cart_items.create(course: course)
      redirect_to courses_path, notice: 'Corso aggiunto al carrello.'
    else
      redirect_to courses_path, alert: 'Errore durante l\'aggiunta del corso al carrello.'
    end
  end

  def remove_course
    cart_item = @cart.cart_items.find_by(course_id: params[:course_id])
    if cart_item&.destroy
      redirect_to @cart, notice: 'Corso rimosso dal carrello.'
    else
      redirect_to @cart, alert: 'Errore durante la rimozione del corso dal carrello.'
    end
  end

  def purchase
    if @cart.cart_items.each do |item|
      current_user.purchases.create(course: item.course)
    end
    @cart.cart_items.destroy_all
    redirect_to bought_courses_path, notice: 'Acquisto completato con successo.'
  else
    redirect_to @cart, alert: 'Errore durante l\'acquisto.'
  end
  end

  private

  def set_cart
    @cart = current_user.cart || current_user.create_cart
  end
end
