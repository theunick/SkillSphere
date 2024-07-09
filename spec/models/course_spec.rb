require 'rails_helper'

RSpec.describe Course, type: :model do
  let(:seller) { Account.create!(name: 'Test Seller', email: 'seller@example.com', role: 'seller') }

  it 'is valid with valid attributes' do
    course = Course.new(title: 'My New Course', category: 'My New Category', description: 'This is a description of my new course', price: 99, seller_id: seller.id)
    expect(course).to be_valid
  end

  it 'is not valid without a title' do
    course = Course.new(title: nil, seller_id: seller.id)
    expect(course).not_to be_valid
  end

  # Altri test di validazione e associazione
end
