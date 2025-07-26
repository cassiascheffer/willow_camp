# Rack::Attack logging subscriptions
module Middleware
  class RackAttackLogger
    def self.subscribe_to_notifications
      # Log throttled requests
      ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |name, start, finish, instrumenter_id, payload|
        req = payload[:request]
        request_info = {
          timestamp: Time.current.iso8601,
          event: "throttled",
          matched_rule: req.env["rack.attack.matched"],
          discriminator: req.env["rack.attack.match_discriminator"],
          match_data: req.env["rack.attack.match_data"],
          ip: req.ip,
          path: req.path,
          method: req.request_method,
          user_agent: req.user_agent,
          referer: req.referer
        }

        Rails.logger.warn "[Rack::Attack] Request throttled", request_info
      end

      # Log blocked requests
      ActiveSupport::Notifications.subscribe("blocklist.rack_attack") do |name, start, finish, instrumenter_id, payload|
        req = payload[:request]
        request_info = {
          timestamp: Time.current.iso8601,
          event: "blocked",
          matched_rule: req.env["rack.attack.matched"],
          ip: req.ip,
          path: req.path,
          method: req.request_method,
          user_agent: req.user_agent,
          referer: req.referer
        }

        Rails.logger.error "[Rack::Attack] Request blocked", request_info
      end

      # Log safelisted requests
      ActiveSupport::Notifications.subscribe("safelist.rack_attack") do |name, start, finish, instrumenter_id, payload|
        req = payload[:request]
        request_info = {
          timestamp: Time.current.iso8601,
          event: "safelisted",
          matched_rule: req.env["rack.attack.matched"],
          ip: req.ip,
          path: req.path,
          method: req.request_method
        }

        Rails.logger.info "[Rack::Attack] Request safelisted", request_info
      end
    end
  end
end
