# Rails Semantic Logger Configuration
# This initializer provides additional configuration for the Rails Semantic Logger

Rails.application.configure do
  # Set backtrace level for errors
  config.semantic_logger.backtrace_level = :error

  # Configure log level for test environment
  if Rails.env.test?
    config.log_level = :warn
  end

  # Development-specific configuration for better debugging
  if Rails.env.development?
    # Disable file appender
    config.rails_semantic_logger.add_file_appender = false
    config.rails_semantic_logger.ap_options = {multiline: false}
    config.rails_semantic_logger.console_logger = true

    # Use colored output for better readability
    config.rails_semantic_logger.format = :color

    # Quiet assets and health check logs
    config.rails_semantic_logger.quiet_assets = true
    config.rails_semantic_logger.filter = ->(log) {
      # Filter out noisy Rails logs in development
      return false if log.name == "ActionView" && log.message&.include?("Rendered")
      return false if log.name == "ActiveRecord" && log.level < :info
      true
    }
  end

  # Production-specific configuration optimized for Scout APM
  if Rails.env.production?
    # Disable file appender
    config.rails_semantic_logger.add_file_appender = false

    # Load custom Scout APM formatter
    require Rails.root.join("lib/scout_apm_log_formatter")

    # Use custom Scout APM formatter
    config.semantic_logger.add_appender(
      io: $stdout,
      formatter: ScoutApmLogFormatter.new,
      filter: ->(log) {
        # Add Scout APM context if available
        if defined?(ScoutApm::Context) && ScoutApm::Context.current
          context = ScoutApm::Context.current
          if context.respond_to?(:to_hash) && context.to_hash.any?
            log.named_tags ||= {}
            log.named_tags[:scout_context] = context.to_hash
          end
        end
        true
      }
    )

    # Disable SQL query logging in production (Scout APM handles this)
    config.active_record.logger = nil if ENV["DISABLE_SQL_LOGGING"]
  end

  # Filter sensitive parameters from logs
  config.filter_parameters += [
    :password, :password_confirmation, :token, :api_key, :secret,
    :email, :email_confirmation, :email_address, :auth_token, :access_token,
    :refresh_token, :client_secret, :authorization, :bearer
  ]

  # Customize Rails action_controller payload
  config.after_initialize do
    # Add more context to controller logs
    ActiveSupport::Notifications.subscribe "process_action.action_controller" do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      payload = event.payload

      if payload[:request]
        request = payload[:request]
        payload[:user_agent] = request.user_agent
        payload[:remote_ip] = request.remote_ip
        payload[:request_id] = request.request_id
        payload[:referer] = request.referer

        # Add current user context if available
        if defined?(Current) && Current.respond_to?(:user)
          payload[:user_id] = Current.user&.id
          payload[:user_email] = Current.user&.email
        end
      end
    end

    # Add semantic logger methods to Active Record models
    ActiveSupport.on_load(:active_record) do
      include SemanticLogger::Loggable
    end

    # Add semantic logger methods to Action Controller
    ActiveSupport.on_load(:action_controller) do
      include SemanticLogger::Loggable

      # Add request context to all controller logs
      around_action :with_request_context

      private

      def with_request_context
        SemanticLogger.tagged(
          request_id: request.request_id,
          remote_ip: request.remote_ip,
          method: request.method,
          path: request.path,
          user_id: current_user&.id
        ) do
          yield
        end
      end
    end
  end
end

# Global logger configuration
SemanticLogger.default_level = Rails.env.production? ? :info : :debug

# Add application-wide logging helpers
module ApplicationLogging
  def log_performance(operation, &block)
    logger.measure_info("Performance: #{operation}", &block)
  end

  def log_with_context(level, message, **context)
    logger.public_send(level, message, **context)
  end
end

# Make logging helpers available globally
ActiveSupport.on_load(:active_record) do
  extend ApplicationLogging
end

ActiveSupport.on_load(:action_controller) do
  include ApplicationLogging
end
