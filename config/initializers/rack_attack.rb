# Rack::Attack configuration for rate limiting and security
# https://github.com/rack/rack-attack

require "middleware/rack_attack_logger"

class Rack::Attack
  # Helper method to extract subdomain from host
  def self.extract_subdomain(host)
    return nil if host.nil? || host.empty?

    # Remove port if present
    domain = host.split(":").first.downcase

    # Check for willow.camp subdomains
    if domain.ends_with?(".willow.camp")
      subdomain = domain.sub(".willow.camp", "")
      return subdomain.presence
    end

    # Check for localhost subdomains (for development/test)
    if domain.ends_with?(".localhost")
      subdomain = domain.sub(".localhost", "")
      return subdomain.presence
    end

    # Not a willow.camp or localhost subdomain
    nil
  end

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

  # Throttle requests to reserved subdomains
  throttle("reserved-subdomain-scanner", limit: 10, period: 1.minute) do |req|
    subdomain = extract_subdomain(req.host)
    if subdomain && ::ReservedWords::RESERVED_WORDS.include?(subdomain)
      "#{req.ip}/#{req.user_agent}"
    end
  end

  # Block bad actors who hit the reserved subdomain throttle limit for 24 hours
  blocklist("block-subdomain-scanners") do |req|
    Rack::Attack::Allow2Ban.filter("#{req.ip}/#{req.user_agent}", maxretry: 10, findtime: 1.minute, bantime: 24.hours) do
      subdomain = extract_subdomain(req.host)
      subdomain && ::ReservedWords::RESERVED_WORDS.include?(subdomain)
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

  # Block PHP requests
  blocklist("block-php-requests") do |req|
    path = req.path.downcase
    fullpath = req.fullpath.downcase
    path.end_with?(".php") || fullpath.include?(".php?")
  end

  # Block credential probes
  blocklist("block-creds-probes") do |req|
    fullpath = req.fullpath.downcase
    fullpath.include?(".aws/credentials") ||
      fullpath.include?(".aws%2fcredentials") ||
      fullpath.include?("%252e%252e%252f") ||
      fullpath.match?(/\.\..*credentials/)
  end

  # Block WordPress and admin path probes
  blocklist("block-admin-probes") do |req|
    path = req.path.downcase
    admin_paths = %w[
      /wp-admin
      /wp-login
      /wp-includes
      /wp-content
      /wp-json
      /administrator
      /phpmyadmin
      /pma
      /adminer
      /mysql
      /.env
      /config.php
      /admin.php
    ]
    admin_paths.any? { |admin_path| path.start_with?(admin_path) }
  end

  # Block version control directory access
  blocklist("block-vcs-access") do |req|
    path = req.path.downcase
    vcs_paths = %w[/.git /.svn /.hg /.bzr]
    vcs_paths.any? { |vcs_path| path.start_with?(vcs_path) }
  end

  # Block backup and sensitive file access
  # Block backup directories
  blocklist("block-backup-dirs") do |req|
    path = req.path.downcase
    backup_dirs = %w[/backup /backups /old /tmp /temp]
    backup_dirs.any? { |dir| path.start_with?(dir) }
  end

  # Block sensitive files
  blocklist("block-sensitive-files") do |req|
    path = req.path.downcase
    sensitive_files = %w[
      /web.config /htaccess /htpasswd /composer.json /package.json
      /dockerfile /docker-compose.yml /xmlrpc.php /readme.html
      /license.txt /changelog.txt
    ]
    sensitive_files.any? { |file| path == file || path.start_with?("#{file}?") }
  end

  # Block risky file extensions
  blocklist("block-risky-extensions") do |req|
    fullpath = req.fullpath.downcase
    risky_extensions = %w[.bak .backup .old .orig .tmp .sql .zip .tar.gz .rar .log]
    risky_extensions.any? { |ext| fullpath.include?(ext) }
  end

  # Block server info disclosure
  blocklist("block-server-info") do |req|
    path = req.path.downcase
    info_paths = %w[
      /server-status /server-info /nginx_status /status
      /info.php /test.php /phpinfo.php /phptest.php
    ]
    info_paths.any? { |info_path| path.start_with?(info_path) }
  end

  # Block dependency directory access
  blocklist("block-dependencies") do |req|
    path = req.path.downcase
    dep_paths = %w[/vendor /node_modules /cgi-bin /fcgi-bin]
    dep_paths.any? { |dep_path| path.start_with?(dep_path) }
  end

  # Block path traversal attempts
  blocklist("block-path-traversal") do |req|
    fullpath = req.fullpath
    # Check for directory traversal patterns
    fullpath.include?("../") ||
      fullpath.include?("..\\") ||
      fullpath.include?("%2e%2e%2f") ||
      fullpath.include?("%2e%2e%5c") ||
      fullpath.include?("%252e%252e%252f")
  end

  # Block Ghost CMS requests
  blocklist("block-ghost-requests") do |req|
    req.path.downcase.start_with?("/.ghost")
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
  self.blocklisted_responder = lambda do |request|
    # Check if this is a subdomain scanner being blocked
    matched = request.env["rack.attack.matched"]

    # If blocked due to subdomain scanning, return 404
    if matched == "block-subdomain-scanners"
      html_content = File.read(Rails.root.join("public", "404.html"))
      [404, {"Content-Type" => "text/html"}, [html_content]]
    else
      # Default forbidden response for other blocks
      [403, {}, ["Forbidden\n"]]
    end
  end
end

# Subscribe to rack attack notifications for logging
Middleware::RackAttackLogger.subscribe_to_notifications
