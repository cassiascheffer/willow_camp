Rails.application.routes.draw do
  resource :session

  get "dashboard" => "dashboard#show", :as => :dashboard
  namespace :dashboard do
    namespace :settings do
      resources :about_pages, param: :slug, path: :pages
    end
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
    namespace :posts do
      get "/rss", to: "feed#show", defaults: {format: "rss"}, as: :rss
      get "/atom", to: "feed#show", defaults: {format: "atom"}, as: :atom
      get "/json", to: "feed#show", defaults: {format: "json"}, as: :json
    end
  end

  namespace :api do
    resources :posts, only: %i[index show create update destroy], param: :slug
  end

  get "up" => "rails/health#show", :as => :rails_health_check
  root "home#show"
end
