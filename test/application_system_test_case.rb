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
      browser_options = {
        "no-sandbox": nil,
        "disable-dev-shm-usage": nil,
        "disable-gpu": nil
      }

      driver_options = {
        window_size: [1400, 1400],
        process_timeout: 60,
        timeout: 30,
        headless: true,
        browser_options: browser_options
      }

      # Add additional configuration for CI environment
      if ENV["CI"] == "true" || ENV["GITHUB_ACTIONS"] == "true"
        browser_options["disable-setuid-sandbox"] = nil
        browser_options["disable-features"] = "VizDisplayCompositor"
        browser_options["disable-web-security"] = nil
        browser_options["disable-site-isolation-trials"] = nil

        # Use explicit Chrome path if available
        if ENV["CHROME_PATH"] && File.exist?(ENV["CHROME_PATH"])
          driver_options[:browser_path] = ENV["CHROME_PATH"]
        elsif File.exist?("/usr/bin/google-chrome")
          driver_options[:browser_path] = "/usr/bin/google-chrome"
        end

        # Debug output in CI
        puts "Cuprite CI Configuration:"
        puts "  Browser path: #{driver_options[:browser_path]}"
        puts "  Process timeout: #{driver_options[:process_timeout]}"
        puts "  Headless: #{driver_options[:headless]}"
      end

      Capybara::Cuprite::Driver.new(app, driver_options)
    end

    driven_by :cuprite
  end
end
