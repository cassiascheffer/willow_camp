Rails.application.routes.draw do
  resources :users, only: %i[ new create ]
  resource :session
  resources :passwords, param: :token
  get "dashboard" => "dashboard#show", as: :dashboard
  namespace :dashboard do
    resources :posts, except: %i[ index show ]
  end
  constraints(subdomain: /.+/) do
    get "/", to: "posts#index", as: :posts
    get "/:slug", to: "posts#show", as: :post
  end
  get "up" => "rails/health#show", as: :rails_health_check
  root "home#show"
end
