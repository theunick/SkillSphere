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
  resources :reports # Aggiungi questa linea per includere le rotte per reports

  get 'bought_courses', to: 'courses#bought', as: 'bought_courses'
  get 'uploaded_courses', to: 'courses#uploaded', as: 'uploaded_courses'

  get '/auth/:provider/callback' => 'session#create'
  get '/auth/failure' => 'session#fail'
  get '/session/destroy' => 'session#destroy'
  
  get "up" => "rails/health#show", as: :rails_health_check
end
