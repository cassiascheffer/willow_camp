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
    config.semantic_logger.application = "willow_camp"
    config.semantic_logger.environment = ENV["RAILS_ENV"] || Rails.env
    config.log_level = ENV["LOG_LEVEL"] || :info

    # Enable Honeybadger Insights appender (production only)
    unless Rails.env.development? || Rails.env.test?
      config.semantic_logger.add_appender(appender: :honeybadger_insights)
    end

    # Switch to JSON Logging output to stdout when running in production or if LOG_TO_CONSOLE is set
    if ENV["LOG_TO_CONSOLE"] || Rails.env.production?
      config.rails_semantic_logger.add_file_appender = false
      config.semantic_logger.add_appender(io: $stdout, formatter: :json)
    end
  end
end
