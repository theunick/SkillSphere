require 'rails_helper'

RSpec.describe AssistanceRequest, type: :model do
  before do
    @account = Account.create!(
      provider: 'google_oauth2',
      uid: '123545',
      name: 'Test Customer',
      email: 'customer@example.com',
      role: 'customer'
    )
  end

  it 'is valid with valid attributes' do
    assistance_request = AssistanceRequest.new(message: 'I need help with my account', status: 'Account', account: @account)
    expect(assistance_request).to be_valid
  end

  it 'is not valid without a message' do
    assistance_request = AssistanceRequest.new(status: 'Account', account: @account)
    expect(assistance_request).to_not be_valid
  end

  it 'is not valid without a status' do
    assistance_request = AssistanceRequest.new(message: 'I need help with my account', account: @account)
    expect(assistance_request).to_not be_valid
  end

  it 'is not valid with an invalid status' do
    assistance_request = AssistanceRequest.new(message: 'I need help with my account', status: 'InvalidStatus', account: @account)
    expect(assistance_request).to_not be_valid
  end

  it 'is not valid without an account' do
    assistance_request = AssistanceRequest.new(message: 'I need help with my account', status: 'Account')
    expect(assistance_request).to_not be_valid
  end
end
