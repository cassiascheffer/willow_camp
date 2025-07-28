class ScoutApmLogFormatter < SemanticLogger::Formatters::Json
  def call(log, logger)
    # Start with standard JSON format
    hash = super

    # Add Scout APM specific fields
    if defined?(ScoutApm::Context) && ScoutApm::Context.current
      context = ScoutApm::Context.current

      # Add Scout context information
      if context.respond_to?(:to_hash) && context.to_hash.any?
        hash[:scout_context] = context.to_hash
      end
    end

    # Flatten named_tags for better Scout APM parsing
    if hash[:named_tags]&.any?
      hash[:named_tags].each do |key, value|
        hash[key] = value unless hash.key?(key)
      end
    end

    # Add service information
    hash[:service] = {
      name: Rails.application.class.module_parent_name.underscore,
      version: ENV["APP_VERSION"] || "unknown",
      environment: Rails.env
    }

    # Ensure timestamp is in ISO8601 format
    hash[:timestamp] = log.time.iso8601(3)

    # Add duration in milliseconds if present
    if log.duration
      hash[:duration_ms] = log.duration
    end

    # Structure error information for Scout APM
    if log.exception
      hash[:error] = {
        class: log.exception.class_name,
        message: log.exception.message,
        backtrace: log.exception.backtrace&.first(10)
      }
    end

    # Convert to JSON
    hash.to_json
  end
end
