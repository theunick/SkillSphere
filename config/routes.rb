Rails.application.routes.draw do

  devise_for :users
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
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get 'bought_courses', to: 'courses#bought', as: 'bought_courses'
  get 'uploaded_courses', to: 'courses#uploaded', as: 'uploaded_courses'
  
  get '/auth/:provider/callback' => 'session#create'
  get '/auth/failure' => 'session#fail'
  get '/session/destroy' => 'session#destroy'

  resource :account, only: [:show, :index] do
    post 'create_assistance', on: :member
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
