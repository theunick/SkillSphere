require 'rails_helper'

RSpec.describe 'Cart and Purchase Integration', type: :request do
  before do
    @customer = Account.create!(
      provider: 'google_oauth2',
      uid: '123456',
      name: 'Test Customer',
      email: 'customer@example.com',
      role: 'customer'
    )

    @seller = Account.create!(
      provider: 'google_oauth2',
      uid: '654321',
      name: 'Test Seller',
      email: 'seller@example.com',
      role: 'seller'
    )

    @course = Course.create!(
      title: 'Test Course',
      category: 'Test Category',
      description: 'This is a test course description',
      price: 99,
      seller: @seller
    )

    CartItem.create!(cart: @customer.cart, course: @course)
  end

  it 'allows a customer to view their cart and proceed to purchase' do
    sign_in @customer
    get cart_path(@customer.cart)
    expect(response.body).to include('Il tuo carrello')
    expect(response.body).to include('Test Course')

    post purchase_path, params: { course_id: @course.id }
    expect(response).to redirect_to(stripe_checkout_path)
  end
end
