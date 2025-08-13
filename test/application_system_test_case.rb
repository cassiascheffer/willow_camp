require "test_helper"
require "capybara/cuprite"
require_relative "system/system_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include BetterRailsSystemTests
  include CupriteHelpers

  driven_by Capybara.javascript_driver

  def setup
    super
    # Use JS driver always

    # Store original host for cleanup
    @original_host = Rails.application.default_url_options[:host]
    # Make urls in mailers contain the correct server host.
    # This is required for testing links in emails (e.g., via capybara-email).
    Rails.application.default_url_options[:host] = Capybara.server_host
  end

  def teardown
    # Restore original host
    Rails.application.default_url_options[:host] = @original_host
    super
  end
end
