Rails.application.routes.draw do
  get 'articles/new'
  get 'articles/create'
  get 'articles/show'
  get 'articles/index'
  get 'articles/destroy'
  devise_for :users
  root to: "pages#home"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
