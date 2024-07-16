require 'rails_helper'

RSpec.describe 'Contacting Support', type: :system do
  before do
    driven_by(:selenium_chrome_headless)

    # Fake account
    @customer = Account.create!(
      provider: 'google_oauth2',
      uid: '678910',
      name: 'Test User',
      email: 'user@example.com',
      role: 'customer'
    )

    if @customer.save
      puts "Account created: #{@customer.inspect}"
    else
      puts "Account creation errors: #{@customer.errors.full_messages.join(', ')}"
    end
    raise "Account not created" unless @customer.persisted?

    # Set session
    page.set_rack_session(user_id: @customer.uid)
  end

  it 'allows a user to contact support' do
    visit root_path

    expect(page).to have_link('Account')

    click_link 'Account'

    expect(page).to have_content('Nuova Richiesta Assistenza')

    fill_in 'Descrizione', with: 'I am experiencing an issue with my account'
    select 'Altro', from: 'Argomento'
    click_button 'Invia'

    expect(page).to have_content('Richiesta di assistenza inviata con successo.')
  end
end
