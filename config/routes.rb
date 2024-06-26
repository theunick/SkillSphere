# config/routes.rb
Rails.application.routes.draw do
  root 'courses#index'
  resources :courses do
    member do
      post 'upload_file'
      get 'share_drive'
    end
  end

  get '/auth/:provider/callback' => 'session#create'
  get '/auth/failure' => 'session#fail'
  get '/session/destroy' => 'session#destroy'
end
