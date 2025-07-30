require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module WillowCamp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Setup structured logging with Semantic Logger
    config.log_level = ENV["LOG_LEVEL"] || (Rails.env.production? ? :info : :debug)
    config.semantic_logger.application = "willow_camp"
    config.semantic_logger.environment = ENV["RAILS_ENV"] || Rails.env
    config.semantic_logger.host = ENV["HOSTNAME"] || Socket.gethostname
    config.semantic_logger.add_appender(appender: :honeybadger_insights)
    config.rails_semantic_logger.processing = false
    config.rails_semantic_logger.quiet_assets = true
    config.rails_semantic_logger.rendered = false
    config.rails_semantic_logger.semantic = true
    config.rails_semantic_logger.started = false
  end
end
