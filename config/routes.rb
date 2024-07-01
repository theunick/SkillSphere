Rails.application.routes.draw do
  resources :courses do
    member do
      post 'upload_file'
      get 'share_drive'
    end
  end

  get 'home/index'
  root 'home#index'
  resources :courses
  resources :accounts
  resources :reports
  resources :admins

  resources :accounts do
    resources :assistance_requests
  end
  
  post 'accounts/:id/create_assistance_request', to: 'accounts#create_assistance_request'
  
  resources :accounts do
    member do
      post 'create_assistance_request'
    end
  
    collection do
      get 'assistance_requests'
    end
  end   

  get 'assistance_requests', to: 'accounts#assistance_requests'

  get 'bought_courses', to: 'courses#bought', as: 'bought_courses'
  get 'uploaded_courses', to: 'courses#uploaded', as: 'uploaded_courses'

  # Rotte per l'autenticazione con Google
  get 'auth/:provider/callback', to: 'session#google_auth'
  get 'auth/failure', to: redirect('/')
  post 'auth/google_oauth2', to: redirect('/auth/google_oauth2')
  get '/session/destroy' => 'session#destroy'

  # Rotte per l'autenticazione dei venditori
  get 'seller_login', to: 'session#new', as: 'new_session'
  post 'seller_login', to: 'session#create', as: 'session'
  delete 'seller_logout', to: 'session#destroy', as: 'destroy_session'

  get "up" => "rails/health#show", as: :rails_health_check
end
