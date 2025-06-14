module SecureDomainRedirect
  extend ActiveSupport::Concern

  private

  def secure_redirect_to_custom_domain(author, current_host, current_path)
    return false unless author&.should_redirect_to_custom_domain?(current_host)

    # Additional security validation
    custom_domain = author.custom_domain
    return false unless valid_redirect_domain?(custom_domain)

    # Construct secure redirect URL
    redirect_url = build_secure_redirect_url(custom_domain, current_path)

    redirect_to redirect_url,
      status: :moved_permanently,
      allow_other_host: true

    true
  end

  def valid_redirect_domain?(domain)
    return false if domain.blank?

    # Ensure domain matches the stored format validation
    return false unless domain.match?(/\A[a-z0-9\-]+(\.[a-z0-9\-]+)*\.[a-z]{2,}\z/)

    # Prevent localhost, IP addresses, and other potentially dangerous domains
    return false if domain.match?(/localhost|127\.0\.0\.1|0\.0\.0\.0|::1/)
    return false if domain.match?(/^\d+\.\d+\.\d+\.\d+$/) # IPv4
    return false if domain.match?(/^\[?[\da-f:]+\]?$/i) # IPv6

    # Prevent willow.camp domains (should use subdomain instead)
    return false if domain.ends_with?(".willow.camp") || domain == "willow.camp"

    # Additional length check
    return false if domain.length > 253 # Max domain length

    true
  end

  def build_secure_redirect_url(domain, path)
    # Sanitize the path to prevent injection
    safe_path = sanitize_redirect_path(path)

    # Use HTTPS for custom domains
    "https://#{domain}#{safe_path}"
  end

  def sanitize_redirect_path(path)
    return "/" if path.blank?

    # Ensure path starts with /
    path = "/#{path}" unless path.start_with?("/")

    # Remove any null bytes or dangerous characters
    path = path.gsub(/[\x00-\x1f\x7f]/, "")

    # Limit path length to prevent abuse
    path = path[0, 2048] if path.length > 2048

    path
  end

  def set_author_with_secure_redirect
    @author = User.find_by_domain(request.host)

    if @author.nil?
      redirect_to root_url(subdomain: false), allow_other_host: true
      return
    end

    # Use secure redirect method
    if secure_redirect_to_custom_domain(@author, request.host, request.fullpath)
      nil
    end
  end
end
