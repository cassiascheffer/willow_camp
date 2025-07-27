module RequestLogging
  extend ActiveSupport::Concern

  included do
    # Set up logging context for all controller actions
    around_action :with_request_logging
  end

  private

  def with_request_logging
    # Build context hash with all relevant information
    context = build_logging_context

    # Log request start
    logger.info "Request started", context

    # Track performance
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    # Execute action with semantic logger context
    SemanticLogger.tagged(context) do
      yield
    end
  ensure
    # Log request completion with duration
    if start_time
      duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
      logger.info "Request completed",
        duration_ms: (duration * 1000).round(2),
        status: response.status
    end
  end

  def build_logging_context
    context = {
      request_id: request.request_id,
      method: request.method,
      path: request.path,
      remote_ip: request.remote_ip,
      user_agent: request.user_agent,
      referer: request.referer,
      controller: controller_name,
      action: action_name,
      subdomain: request.subdomain,
      host: request.host,
      domain: request.domain,
      format: request.format.symbol,
      xhr: request.xhr?
    }

    # Add user context if available
    if user_signed_in?
      context.merge!(
        user_id: current_user.id,
        user_email: current_user.email,
        user_subdomain: current_user.subdomain,
        user_role: current_user.try(:role)
      )
    end

    # Add blog context for multi-tenant setup
    if @current_blog.present?
      context.merge!(
        blog_id: @current_blog.id,
        blog_subdomain: @current_blog.subdomain,
        blog_custom_domain: @current_blog.custom_domain
      )
    end

    context
  end

  # Helper method for logging events within controllers
  def log_event(event_name, **additional_context)
    logger.info(event_name, additional_context)
  end

  # Helper for logging errors with context
  def log_error(error, **additional_context)
    logger.error(
      error.message,
      error_class: error.class.name,
      backtrace: error.backtrace&.first(5),
      **additional_context
    )
  end

  # Helper for performance logging
  def log_performance(operation)
    logger.measure_info("Performance: #{operation}") do
      yield
    end
  end
end
