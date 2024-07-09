require 'rails_helper'

RSpec.describe CoursesController, type: :controller do
  let(:seller) { Account.create!(name: 'Test Seller', email: 'seller@example.com', role: 'seller', uid: '12345', provider: 'google_oauth2') }
  let(:valid_attributes) { { title: 'My New Course', category: 'My New Category', description: 'This is a description of my new course', price: 99 } }

  before do
    session[:user_id] = seller.uid
  end

  describe 'POST #create' do
    it 'creates a new course' do
      expect {
        post :create, params: { course: valid_attributes }
      }.to change(Course, :count).by(1)

      expect(response).to redirect_to(Course.last)
    end
  end
end
