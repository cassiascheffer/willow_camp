require "test_helper"
require "capybara/cuprite"

# Set default wait time for Capybara
Capybara.default_max_wait_time = 5

Capybara.register_driver(:cuprite) do |app|
  browser_options = {
    "no-sandbox": nil,
    "disable-dev-shm-usage": nil,
    "disable-gpu": nil,
    "disable-setuid-sandbox": nil
  }

  Capybara::Cuprite::Driver.new(
    app,
    window_size: [1400, 1400],
    process_timeout: 30,  # How long to wait for Chrome to start
    timeout: 30,  # Default timeout for commands
    headless: !ENV["HEADLESS"].in?(%w[n 0 no false]),
    inspector: ENV["INSPECTOR"].present?,
    browser_options: browser_options,
    browser_path: ENV["CHROME_PATH"] || "/usr/bin/google-chrome"
  )
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite
end
