# Constraint class for custom domains and subdomains

class DomainConstraint
  def matches?(request)
    host = request.host.split(":").first.downcase

    # In local environments (dev/test), be permissive - allow any subdomain
    if Rails.env.local?
      return true if request.subdomain.present?
    end

    # Allow if it's a subdomain of willow.camp
    return true if host.ends_with?(".willow.camp") && request.subdomain.present?

    # Allow if it's a custom domain (not willow.camp and has a blog)
    if !host.ends_with?(".willow.camp")
      return Blog.by_domain(host).exists?
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
  get "dashboard/security" => "dashboard/security#show", :as => :dashboard_security
  get "dashboard/:blog_subdomain" => "dashboard#show", :as => :blog_dashboard
  get "dashboard/:blog_subdomain/tags" => "dashboard/tags#index", :as => :blog_dashboard_tags
  get "dashboard/:blog_subdomain/settings" => "dashboard/settings#show", :as => :blog_dashboard_settings
  namespace :dashboard do
    namespace :settings do
      resources :about_pages, param: :slug, path: :pages
    end
    resource :settings, only: %i[show]
    resources :users, only: %i[edit update]
    resources :tokens, only: %i[create destroy]
    resource :subdomain, only: %i[update]
    resources :tags, only: %i[index update destroy]
    resources :blogs, only: %i[create]

    # Blog-scoped resources
    scope "blogs/:blog_subdomain" do
      resources :posts, only: %i[edit update destroy]
      resources :featured_posts, only: %i[update]
      resources :untitled_posts, only: %i[create]
    end
  end

  resources :previews, only: %i[show]

  constraints(DomainConstraint.new) do
    # Tags
    get "/tags", to: "blogs/tags#index", as: :tags
    get "/t/:tag", to: "blogs/tags#show", as: :tag
    # Posts
    get "/", to: "blogs/posts#index", as: :posts

    # Feed formats
    get "/posts/rss", to: "blogs/feed#show", defaults: {format: "rss"}, as: :posts_rss
    get "/posts/atom", to: "blogs/feed#show", defaults: {format: "atom"}, as: :posts_atom
    get "/posts/json", to: "blogs/feed#show", defaults: {format: "json"}, as: :posts_json

    # Feed subscription page
    get "/subscribe", to: "blogs/feed#subscribe", as: :subscribe

    # Sitemap
    get "/sitemap.:format", to: "blogs/sitemap#show", as: :sitemap

    # Robots.txt
    get "/robots.:format", to: "blogs/robots#show", as: :robots

    # This catch-all route must come last to avoid matching other specific routes
    get "/:slug", to: "blogs/posts#show", as: :post
  end

  namespace :api do
    resources :posts, only: %i[index show create update destroy], param: :slug
    get "domain-validation", to: "domain_validation#validate"
  end

  get "up" => "rails/health#show", :as => :rails_health_check

  # Documentation
  get "/docs", to: "documentations#show", as: :documentation

  # Terms of Service
  get "/terms", to: "terms#show", as: :terms

  # Robots.txt for root domain
  get "/robots.:format", to: "robots#show", as: :root_robots

  root "home#show"
end
