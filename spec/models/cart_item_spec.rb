require 'rails_helper'

RSpec.describe CartItem, type: :model do
  it 'can add a course to the cart' do
    customer = Account.create!(
      provider: 'google_oauth2',
      uid: '123456',
      name: 'Test Customer',
      email: 'customer@example.com',
      role: 'customer'
    )

    seller = Account.create!(
      provider: 'google_oauth2',
      uid: '654321',
      name: 'Test Seller',
      email: 'seller@example.com',
      role: 'seller'
    )

    course = Course.create!(
      title: 'Test Course',
      category: 'Test Category',
      description: 'This is a test course description',
      price: 99,
      seller: seller
    )

    cart_item = CartItem.create!(cart: customer.cart, course: course)
    expect(customer.cart.courses).to include(course)
  end
end

RSpec.describe Course, type: :model do
  it 'has a valid factory' do
    seller = Account.create!(
      provider: 'google_oauth2',
      uid: '654321',
      name: 'Test Seller',
      email: 'seller@example.com',
      role: 'seller'
    )

    course = Course.create!(
      title: 'Test Course',
      category: 'Test Category',
      description: 'This is a test course description',
      price: 99,
      seller: seller
    )

    expect(course).to be_valid
  end
end
