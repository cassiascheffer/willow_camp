module RequestLogging
  extend ActiveSupport::Concern

  included do
    before_action :log_request_details
  end

  private

  def log_request_details
    request_info = {
      method: request.method,
      path: request.path,
      ip: request.remote_ip,
      user_agent: request.user_agent,
      referer: request.referer,
      controller: controller_name,
      action: action_name,
      subdomain: request.subdomain,
      host: request.host,
      domain: request.domain
    }

    if user_signed_in?
      request_info[:user_id] = current_user.id
      request_info[:subdomain] = current_user.subdomain
    end

    logger.info "Request started", request_info
  end
end
