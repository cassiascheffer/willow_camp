Rails.application.routes.draw do
  namespace :dashboard do
    get "posts/new"
    get "posts/create"
    get "posts/edit"
    get "posts/update"
    get "posts/destroy"
  end
  get "dashboard/show"
  resources :posts
  resource :session
  resources :passwords, param: :token
  get "dashboard" => "dashboard#show", as: :dashboard
  get "up" => "rails/health#show", as: :rails_health_check
  root "home#show"
end
