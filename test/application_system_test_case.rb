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
    # Register and use Cuprite driver
    Capybara.register_driver(:cuprite) do |app|
      Capybara::Cuprite::Driver.new(app,
        window_size: [1400, 1400],
        process_timeout: ENV["CI"] ? 30 : 10,
        timeout: 15,
        headless: ENV["CI"] ? "new" : true,
        browser_options: {
          "no-sandbox": nil,
          "disable-dev-shm-usage": nil,
          "disable-features": "PasswordLeakDetection",
          "disable-extensions": nil,
          "disable-background-timer-throttling": nil,
          "disable-backgrounding-occluded-windows": nil,
          "disable-gpu": ENV["CI"] ? nil : false,
          "disable-software-rasterizer": ENV["CI"] ? nil : false
        })
    end

    driven_by :cuprite
  end
end
