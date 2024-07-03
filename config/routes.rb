Rails.application.routes.draw do
  resources :courses do
    member do
      post 'upload_file'
      get 'share_drive'
      post 'add_to_cart'
    end
  end

  get 'home/index'
  root 'home#index'
  resources :courses
  resources :accounts do
    resources :assistance_requests, only: [:create, :destroy, :index, :update]
  end

  resources :reports, only: [:create, :destroy]
  get 'reported_courses', to: 'reports#index', as: 'reported_courses'
  get 'assistance_requests', to: 'assistance_requests#index', as: 'all_assistances'

  resources :admins

  get 'bought_courses', to: 'courses#bought', as: 'bought_courses'
  get 'uploaded_courses', to: 'courses#uploaded', as: 'uploaded_courses'

  # Rotte per l'autenticazione con Google
  get 'auth/:provider/callback', to: 'sessions#google_auth'
  get 'auth/failure', to: redirect('/')
  post 'auth/google_oauth2', to: redirect('/auth/google_oauth2')
  get '/session/destroy' => 'sessions#destroy'

  # Rotte per l'autenticazione dei venditori
  get 'seller_login', to: 'sessions#new', as: 'new_session'
  post 'seller_login', to: 'sessions#create', as: 'session'
  delete 'seller_logout', to: 'sessions#destroy', as: 'destroy_session'

  get "up" => "rails/health#show", as: :rails_health_check
end
