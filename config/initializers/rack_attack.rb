# Rack::Attack configuration for rate limiting and security
# https://github.com/rack/rack-attack

require "middleware/rack_attack_logger"

class Rack::Attack
  # Use Rails cache store for tracking throttles
  Rack::Attack.cache.store = Rails.cache

  ### Safelists ###

  # Always allow requests from localhost
  safelist("allow-localhost") do |req|
    req.ip == "127.0.0.1" || req.ip == "::1"
  end

  ### Throttles ###

  # Throttle all requests by IP (300 requests per 5 minutes)
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  # Throttle login attempts by IP address
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/login" && req.post?
      req.ip
    end
  end

  # Throttle login attempts by email address
  throttle("logins/email", limit: 5, period: 20.seconds) do |req|
    if req.path == "/login" && req.post?
      req.params["email"].to_s.downcase.gsub(/\s+/, "").presence
    end
  end

  # Throttle password reset requests by email
  throttle("password-resets/email", limit: 5, period: 15.minutes) do |req|
    if req.path == "/password_resets" && req.post?
      req.params["email"].to_s.downcase.gsub(/\s+/, "").presence
    end
  end

  # Block unauthenticated API requests
  blocklist("block-unauthenticated-api") do |req|
    req.path.start_with?("/api") && !req.env["HTTP_AUTHORIZATION"]&.start_with?("Bearer ")
  end

  # Throttle authenticated API requests by bearer token (300 requests per minute)
  throttle("api/token", limit: 300, period: 1.minute) do |req|
    if req.path.start_with?("/api") && req.env["HTTP_AUTHORIZATION"]&.start_with?("Bearer ")
      # Extract the token from Authorization header for rate limiting
      req.env["HTTP_AUTHORIZATION"].split(" ").last
    end
  end

  # Throttle post creation (10 posts per hour per IP)
  throttle("posts/ip", limit: 10, period: 1.hour) do |req|
    if req.path.match?(%r{^/dashboard/posts}) && req.post?
      req.ip
    end
  end

  # Throttle comment creation (30 comments per hour per IP)
  throttle("comments/ip", limit: 30, period: 1.hour) do |req|
    if req.path.match?(%r{/comments}) && req.post?
      req.ip
    end
  end

  ### Blocklists ###
  blocklist("block-php-requests") do |req|
    path = req.path.downcase
    fullpath = req.fullpath.downcase
    path.end_with?(".php") || fullpath.include?(".php?")
  end

  blocklist("block-creds-probes") do |req|
    fullpath = req.fullpath.downcase
    fullpath.include?(".aws/credentials") ||
      fullpath.include?(".aws%2fcredentials") ||
      fullpath.include?("%252e%252e%252f") ||
      fullpath.match?(/\.\..*credentials/)
  end

  # Block suspicious requests to admin paths
  blocklist("block-admin-probes") do |req|
    req.path.downcase
    admin_paths = %w[/wp-admin /wp-login /administrator /phpmyadmin /.env /config.php /admin.php]
    admin_paths.any? { |admin_path| path.start_with?(admin_path) }
  end

  ### Custom Responses ###

  # Customize response when request is throttled
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.matched_data"]
    now = match_data[:epoch_time]
    headers = {
      "RateLimit-Limit" => match_data[:limit].to_s,
      "RateLimit-Remaining" => "0",
      "RateLimit-Reset" => (now + (match_data[:period] - now % match_data[:period])).to_s
    }

    [429, headers, ["Rate limit exceeded. Try again later.\n"]]
  end

  # Customize response when request is blocked
  self.blocklisted_responder = lambda do |_request|
    [403, {}, ["Forbidden\n"]]
  end
end

# Subscribe to rack attack notifications for logging
Middleware::RackAttackLogger.subscribe_to_notifications
