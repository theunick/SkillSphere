require 'rails_helper'

RSpec.describe AssistanceRequestsController, type: :controller do
  before do
    @user = Account.create!(
      provider: 'google_oauth2',
      uid: '123545',
      name: 'Test User',
      email: 'user@example.com',
      role: 'customer'
    )
    session[:user_id] = @user.uid
  end

  describe 'POST #create' do
    it 'creates a new assistance request' do
      post :create, params: { account_id: @user.id, assistance_request: { message: 'I need help with my account', status: 'Account' } }
      
      expect(response).to redirect_to(accounts_path)
      expect(flash[:notice]).to eq('Richiesta di assistenza inviata con successo.')
    end
  end
end
