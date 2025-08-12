require "test_helper"
require "capybara/cuprite"

# Register Cuprite driver with CI-specific configuration
Capybara.register_driver(:cuprite) do |app|
  browser_options = {
    "no-sandbox": nil,
    "disable-dev-shm-usage": nil,
    "disable-gpu": nil
  }

  driver_options = {
    window_size: [1400, 1400],
    process_timeout: 120,  # Increased to 120 seconds
    timeout: 60,  # Increased timeout
    headless: true,
    browser_options: browser_options
  }

  # Add additional configuration for CI environment
  if ENV["CI"] == "true" || ENV["GITHUB_ACTIONS"] == "true"
    browser_options["disable-setuid-sandbox"] = nil
    browser_options["disable-features"] = "VizDisplayCompositor"
    browser_options["disable-web-security"] = nil
    browser_options["disable-site-isolation-trials"] = nil
    browser_options["disable-blink-features"] = "AutomationControlled"

    # Use explicit Chrome path if available
    if ENV["CHROME_PATH"] && File.exist?(ENV["CHROME_PATH"])
      driver_options[:browser_path] = ENV["CHROME_PATH"]
    elsif File.exist?("/usr/bin/google-chrome")
      driver_options[:browser_path] = "/usr/bin/google-chrome"
    end

    # Debug output in CI
    puts "=" * 60
    puts "Cuprite CI Configuration:"
    puts "  CI Environment: true"
    puts "  Browser path: #{driver_options[:browser_path]}"
    puts "  Process timeout: #{driver_options[:process_timeout]}"
    puts "  Timeout: #{driver_options[:timeout]}"
    puts "  Headless: #{driver_options[:headless]}"
    puts "  Browser options: #{browser_options.inspect}"
    puts "=" * 60
  end

  Capybara::Cuprite::Driver.new(app, driver_options)
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite
end
