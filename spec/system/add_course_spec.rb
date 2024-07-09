require 'rails_helper'

RSpec.describe 'Add a new course', type: :system do
  before do
    driven_by(:selenium_chrome_headless)

    # Fake account
    @seller = Account.create!(
      provider: 'google_oauth2',
      uid: '123545',
      name: 'Test Seller',
      email: 'seller@example.com',
      role: 'seller'
    )

    puts "Account creation errors: #{@seller.errors.full_messages.join(', ')}"
    raise "Account not created" unless @seller.persisted?

    # Utilizzo il middleware rack_session_access per impostare
    # la sessione del test in modo che sembri che l'utente specificato sia loggato.
    # Bypasso l'autenticazione reale e simulo l'accesso di un utente.
    page.set_rack_session(user_id: @seller.uid)
  end

  it 'allows a seller to add a new course' do
    visit root_path

    expect(page).to have_link('Crea corso', id: 'new-course-link')

    click_link 'Crea corso'

    expect(page).to have_content('New Course')

    fill_in 'Title', with: 'My New Course'
    fill_in 'Category', with: 'My New Category'
    fill_in 'Description', with: 'This is a description of my new course'
    fill_in 'Price', with: '99'
    expect(page).to have_button('Create Course')
    click_button 'Create Course'

    expect(page).to have_content('Course was successfully created.')
    expect(page).to have_content('My New Course')
  end
end
