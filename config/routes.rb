Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  get "dashboard" => "dashboard#show", :as => :dashboard
  namespace :dashboard do
    resource :settings, only: %i[show]
    resources :posts, except: %i[index show], param: :slug
    resources :users, only: %i[edit update], param: :slug
    resources :tokens, only: %i[create destroy]
  end

  constraints(subdomain: /.+/) do
    # Tags
    get "/tags", to: "tags#index", as: :tags
    get "/t/:tag", to: "tags#show", as: :tag
    # Posts
    get "/", to: "posts#index", as: :posts
    get "/:slug", to: "posts#show", as: :post

    # Feed formats
    namespace :rss do
      get "/posts", to: "posts#show", defaults: {format: "rss"}, as: :posts
    end
    
    namespace :atom do
      get "/posts", to: "posts#show", defaults: {format: "atom"}, as: :posts
    end
    
    namespace :json do
      get "/posts", to: "posts#show", defaults: {format: "json"}, as: :posts
    end
  end

  namespace :api do
    resources :posts, only: %i[index show create update destroy], param: :slug
  end

  get "up" => "rails/health#show", :as => :rails_health_check
  root "home#show"
end
