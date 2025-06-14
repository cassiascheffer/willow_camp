class Api::DomainValidationController < ApplicationController
  skip_before_action :verify_authenticity_token

  def validate
    domain = params[:domain] || request.headers["Host"]
    # Remove port number if present
    domain = domain.split(":").first if domain.present?

    if valid_domain?(domain)
      head :ok
    else
      head :forbidden
    end
  end

  private

  def valid_domain?(domain)
    return false if domain.blank?

    return true if domain.ends_with?(".willow.camp")

    return true if domain == "willow.camp"

    User.exists?(custom_domain: domain)
  end
end
