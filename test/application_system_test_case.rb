require "test_helper"
require "capybara/cuprite"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  if ENV["CAPYBARA_SERVER_PORT"]
    served_by host: "rails-app", port: ENV["CAPYBARA_SERVER_PORT"]

    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400], options: {
      browser: :remote,
      url: "http://#{ENV["SELENIUM_HOST"]}:4444"
    }
  else
    # Determine if we're in CI environment
    ci_environment = ENV["CI"] == "true" || ENV["GITHUB_ACTIONS"] == "true"

    # Register and use Cuprite driver
    Capybara.register_driver(:cuprite) do |app|
      options = {
        window_size: [1400, 1400],
        process_timeout: 30,
        timeout: 30,
        headless: true,
        browser_options: {
          "no-sandbox": nil,
          "disable-dev-shm-usage": nil,
          "disable-features": "PasswordLeakDetection",
          "disable-extensions": nil,
          "disable-background-timer-throttling": nil,
          "disable-backgrounding-occluded-windows": nil,
          "disable-gpu": nil,
          "disable-software-rasterizer": nil,
          "disable-setuid-sandbox": nil
        }
      }

      # Add more aggressive settings for CI
      if ci_environment
        options[:browser_options]["disable-web-security"] = nil
        options[:browser_options]["disable-site-isolation-trials"] = nil
        options[:wait_time] = 30
        options[:slowmo] = 0.1
      end

      Capybara::Cuprite::Driver.new(app, options)
    end

    driven_by :cuprite
  end
end
