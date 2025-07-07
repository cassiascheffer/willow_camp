# Rails Semantic Logger Configuration
# This initializer provides additional configuration for the Rails Semantic Logger

Rails.application.configure do
  # Set backtrace level for errors
  config.semantic_logger.backtrace_level = :error

  # Configure log level for test environment
  if Rails.env.test?
    config.log_level = :warn
  end

  # Filter sensitive parameters from logs
  config.filter_parameters += [:password, :password_confirmation, :token, :api_key, :secret]
end
