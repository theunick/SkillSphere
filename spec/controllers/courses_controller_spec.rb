require 'rails_helper'

RSpec.describe CoursesController, type: :controller do
  let(:seller) { Account.create!(name: 'Test Seller', email: 'seller@example.com', role: 'seller', uid: '12345', provider: 'google_oauth2') }
  let(:valid_attributes) { { title: 'My New Course', category: 'My New Category', description: 'This is a description of my new course', price: 99, seller: seller } }
  let(:invalid_attributes) { { title: '', category: '', description: '', price: nil, seller: seller } }
  let(:course) { Course.create!(valid_attributes) }

  before do
    # Mocking di current_user e current_seller, simulo l'autenticazione
    allow(controller).to receive(:current_user).and_return(seller)
    allow(controller).to receive(:current_seller).and_return(seller)

    # Stub dei metodi di impressionist, intercetto le chiamate a impressionist e restituisco true
    # Bypasso le chiamate ai metodi di impressionist
    allow(controller).to receive(:impressionist).and_return(true)
    allow(controller).to receive(:impressionist_subapp_filter).and_return(true)
    
    # Simulo sessione e cookies per impressionist
    request.session[:user_id] = seller.uid
    request.cookies[:impressionist] = "test_cookie_value"
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      it 'creates a new course' do
        expect {
          post :create, params: { course: valid_attributes }
        }.to change(Course, :count).by(1)

        expect(response).to redirect_to(Course.last)
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new course' do
        expect {
          post :create, params: { course: invalid_attributes }
        }.to change(Course, :count).by(0)

        expect(response).to render_template(:new)
      end
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      get :show, params: { id: course.to_param }
      expect(response).to be_successful
    end
  end

  describe 'GET #edit' do
    it 'returns a success response' do
      get :edit, params: { id: course.to_param }
      expect(response).to be_successful
    end
  end

  describe 'PATCH #update' do
    context 'with valid parameters' do
      let(:new_attributes) { { title: 'Updated Course' } }

      it 'updates the requested course' do
        patch :update, params: { id: course.to_param, course: new_attributes }
        course.reload
        expect(course.title).to eq('Updated Course')
        expect(response).to redirect_to(course)
      end
    end

    context 'with invalid parameters' do
      it 'renders the edit template' do
        patch :update, params: { id: course.to_param, course: invalid_attributes }
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'marks the course as hidden' do
      course
      expect {
        delete :destroy, params: { id: course.to_param }
      }.to change { course.reload.hidden }.from(false).to(true)

      expect(response).to redirect_to(courses_url)
    end
  end
end
