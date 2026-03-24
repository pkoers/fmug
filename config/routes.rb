Rails.application.routes.draw do
  resources :schedules
  resources :conferences
  resources :users, only: [ :index, :destroy ] do
    patch :admin, on: :member
  end
  resources :invitations, only: [ :create ]
  resources :magic_links, only: [ :create ]
  resources :login_magic_links, only: [ :create ]
  resource :registration, only: [ :create, :destroy ]
  get "/magic-links/:token", to: "magic_links#show", as: :magic_link
  get "/login-magic-links/:token", to: "login_magic_links#show", as: :login_magic_link
  match "/auth/:provider/callback", to: "sessions#create", via: [ :get, :post ]
  match "/auth/failure", to: "sessions#failure", via: [ :get, :post ]
  delete "/logout", to: "sessions#destroy", as: :logout
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  root "pages#landing"
  get "about", to: "pages#about"
  get "privacy", to: "pages#privacy"
  get "agenda", to: "schedules#agenda"
end
