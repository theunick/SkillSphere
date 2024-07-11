require 'rails_helper'

RSpec.describe 'Purchase a course from the cart', type: :system do
  before do
    driven_by(:selenium_chrome_headless)

    # Crea un account fittizio per il cliente
    @customer = Account.create!(
      provider: 'google_oauth2',
      uid: '123456',
      name: 'Test Customer',
      email: 'customer@example.com',
      role: 'customer'
    )

    # Crea un account fittizio per il venditore
    @seller = Account.create!(
      provider: 'google_oauth2',
      uid: '654321',
      name: 'Test Seller',
      email: 'seller@example.com',
      role: 'seller'
    )

    # Assicurati che gli account siano stati creati
    raise "Customer account not created" unless @customer.persisted?
    raise "Seller account not created" unless @seller.persisted?

    # Simula l'accesso dell'utente cliente
    page.set_rack_session(user_id: @customer.uid)
  end

  it 'allows a customer to initiate purchase of a course from the cart' do
    # Crea un corso associato al venditore
    @course = Course.create!(
      title: 'Test Course',
      category: 'Test Category',
      description: 'This is a test course description',
      price: 99,
      seller: @seller
    )

    # Aggiungi il corso al carrello del cliente
    CartItem.create!(cart: @customer.cart, course: @course)

    visit cart_path(@customer.cart)

    expect(page).to have_content('Il tuo carrello')
    expect(page).to have_content('Test Course')

    # Simula l'azione di acquisto con il testo corretto del pulsante
    click_button('Checkout con Stripe', match: :first)

    # Verifica che siamo reindirizzati alla pagina di Stripe
    expect(page).to have_content('Email')
    expect(page).to have_content('Card information')
    expect(page).to have_content('Pay')
  end
end
