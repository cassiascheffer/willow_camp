# Rack::Attack logging subscriptions
module Middleware
  class RackAttackLogger
    def self.subscribe_to_notifications
      # Log throttled requests
      ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |name, start, finish, instrumenter_id, payload|
        req = payload[:request]
        discriminator = req.env["rack.attack.match_discriminator"]

        # Obfuscate email addresses in discriminator
        if discriminator&.include?("@")
          parts = discriminator.split("@")
          username = parts[0]
          domain = parts[1]

          # Keep first and last char of username, mask the rest
          obfuscated_username = if username.length > 2
            username[0] + "*" * (username.length - 2) + username[-1]
          else
            "*" * username.length
          end

          discriminator = "#{obfuscated_username}@#{domain}"
        end

        request_info = {
          timestamp: Time.current.iso8601,
          event: "throttled",
          matched_rule: req.env["rack.attack.matched"],
          discriminator: discriminator,
          match_data: req.env["rack.attack.match_data"],
          ip: req.ip,
          path: req.path,
          method: req.request_method,
          user_agent: req.user_agent,
          referer: req.referer,
          subdomain: req.host.split(".").first,
          host: req.host
        }

        Rails.logger.warn("[Rack::Attack] Request throttled: #{request_info.to_json}")
      end

      # Log blocked requests - disabled to reduce log noise
      # ActiveSupport::Notifications.subscribe("blocklist.rack_attack") do |name, start, finish, instrumenter_id, payload|
      #   req = payload[:request]
      #   request_info = {
      #     timestamp: Time.current.iso8601,
      #     event: "blocked",
      #     matched_rule: req.env["rack.attack.matched"],
      #     ip: req.ip,
      #     path: req.path,
      #     method: req.request_method,
      #     user_agent: req.user_agent,
      #     referer: req.referer,
      #     subdomain: req.host.split(".").first,
      #     host: req.host
      #   }
      #
      #   Rails.logger.error("[Rack::Attack] Request blocked: #{request_info.to_json}")
      # end
    end
  end
end
