class HomeController < ApplicationController
  def index
    @cart = current_user.cart || current_user.create_cart if current_user
  end
end
