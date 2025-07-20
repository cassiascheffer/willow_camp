# Constraint class for custom domains and subdomains

class DomainConstraint
  def matches?(request)
    host = request.host.split(":").first.downcase

    # In local environments (dev/test), be permissive - allow any subdomain if user exists
    if Rails.env.local?
      return true if request.subdomain.present? && User.exists?(subdomain: request.subdomain)
    end

    # Allow if it's a subdomain of willow.camp
    return true if host.ends_with?(".willow.camp") && request.subdomain.present?

    # Allow if it's a custom domain (not willow.camp and has a user)
    if !host.ends_with?(".willow.camp")
      return User.by_domain(host).exists?
    end

    false
  end
end

Rails.application.routes.draw do
  devise_for :users,
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
    resources :posts, only: %i[edit update destroy]
    resources :untitled_posts, only: %i[create]
    resources :users, only: %i[edit update]
    resources :tokens, only: %i[create destroy]
    resource :subdomain, only: %i[update]
  end

  resources :previews, only: %i[show]

  constraints(DomainConstraint.new) do
    # Tags
    get "/tags", to: "blog/tags#index", as: :tags
    get "/t/:tag", to: "blog/tags#show", as: :tag
    # Posts
    get "/", to: "blog/posts#index", as: :posts

    # Feed formats
    get "/posts/rss", to: "blog/feed#show", defaults: {format: "rss"}, as: :posts_rss
    get "/posts/atom", to: "blog/feed#show", defaults: {format: "atom"}, as: :posts_atom
    get "/posts/json", to: "blog/feed#show", defaults: {format: "json"}, as: :posts_json

    # Feed subscription page
    get "/subscribe", to: "blog/feed#subscribe", as: :subscribe

    # Sitemap
    get "/sitemap.:format", to: "blog/sitemap#show", as: :sitemap

    # Robots.txt
    get "/robots.:format", to: "blog/robots#show", as: :robots

    # This catch-all route must come last to avoid matching other specific routes
    get "/:slug", to: "blog/posts#show", as: :post
  end

  namespace :api do
    resources :posts, only: %i[index show create update destroy], param: :slug
    get "domain-validation", to: "domain_validation#validate"
  end

  get "up" => "rails/health#show", :as => :rails_health_check

  # Documentation
  get "/docs", to: "documentations#show", as: :documentation

  # Robots.txt for root domain
  get "/robots.:format", to: "robots#show", as: :root_robots

  root "home#show"
end
