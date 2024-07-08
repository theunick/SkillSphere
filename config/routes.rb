Rails.application.routes.draw do
  get 'sellers/statistics'
  
  resources :courses do
    member do
      post 'upload_file'
      get 'share_drive'
      post 'add_to_cart'
      post 'purchase'
      get 'statistics'
      get 'show_customer'
    end
    resources :reviews, only: [:create]
  end

  get 'home/index'
  root 'home#index'
  
  resources :accounts do
    resources :assistance_requests, only: [:create, :destroy, :index, :update]
    member do
      patch 'make_customer'
      patch 'make_seller'
      patch 'make_admin'
    end
  end

  resource :cart, only: [:show] do
    post 'add_course', to: 'carts#add_course'
    delete 'remove_course', to: 'carts#remove_course'
    post 'purchase', to: 'carts#purchase'
  end

  resources :reports, only: [:create, :destroy]
  get 'reported_courses', to: 'reports#index', as: 'reported_courses'
  get 'assistance_requests', to: 'assistance_requests#index', as: 'all_assistances'

  resources :admins

  get 'bought_courses', to: 'accounts#bought_courses', as: 'bought_courses'
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
  get 'sellers/:id/statistics', to: 'sellers#statistics', as: 'statistics_seller'

  get "up" => "rails/health#show", as: :rails_health_check
end
