require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  if ENV["CAPYBARA_SERVER_PORT"]
    served_by host: "rails-app", port: ENV["CAPYBARA_SERVER_PORT"]

    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400], options: {
      browser: :remote,
      url: "http://#{ENV["SELENIUM_HOST"]}:4444"
    }
  else
    driven_by :selenium, using: :chrome, screen_size: [1400, 1400] do |driver_option|
      driver_option.add_argument('--headless=new')
      driver_option.add_argument('--no-sandbox')
      driver_option.add_argument('--disable-dev-shm-usage')

      # Disable password protection features
      driver_option.add_argument('--disable-features=PasswordLeakDetection')
      driver_option.add_argument('--disable-password-generation')
      driver_option.add_argument('--disable-password-manager-reauthentication')

      # Set preferences to disable password features
      driver_option.add_preference('profile.password_manager_enabled', false)
      driver_option.add_preference('profile.password_manager_leak_detection', false)
    end
  end
end
