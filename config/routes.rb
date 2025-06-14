# Constraint class for custom domains and subdomains
class DomainConstraint
  def matches?(request)
    # Allow if it's a subdomain of willow.camp
    return true if request.host.ends_with?(".willow.camp") && request.subdomain.present?
    # Allow if it's a custom domain (not willow.camp and has a user)
    return true if !request.host.ends_with?(".willow.camp") && User.exists?(custom_domain: request.host)
    false
  end
end

Rails.application.routes.draw do
  devise_for :users,
    skip: %i[unlocks passwords confirmations registrations],
    path_names: {
      sign_in: "login",
      sign_out: "logout",
      password: "secret",
      confirmation: "verification",
      unlock: "unblock",
      registration: "register",
      sign_up: "signup"
    },
    controllers: {
      sessions: "users/sessions",
      registrations: "users/registrations",
      confirmations: "users/confirmations",
      passwords: "users/passwords",
      unlocks: "users/unlocks"
    }

  get "dashboard" => "dashboard#show", :as => :dashboard
  namespace :dashboard do
    namespace :settings do
      resources :about_pages, param: :slug, path: :pages
    end
    resource :settings, only: %i[show]
    resources :posts, except: %i[index show], param: :slug
    resources :users, only: %i[edit update]
    resources :tokens, only: %i[create destroy]
  end

  constraints(DomainConstraint.new) do
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
    get "domain-validation", to: "domain_validation#validate"
  end

  get "up" => "rails/health#show", :as => :rails_health_check

  root "home#show"
end
