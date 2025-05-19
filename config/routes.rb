Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  get "dashboard" => "dashboard#show", as: :dashboard
  namespace :dashboard do
    resource :settings, only: %i[ show ]
    resources :posts, except: %i[ index show ]
    resources :users, only: %i[ edit update ]
    resources :tokens, only: %i[ create destroy ]
  end
  constraints(subdomain: /.+/) do
    get "/", to: "posts#index", as: :posts
    get "/:slug", to: "posts#show", as: :post
  end
  namespace :api do
    resources :posts, only: %i[ create]
  end
  get "up" => "rails/health#show", as: :rails_health_check
  root "home#show"
end
