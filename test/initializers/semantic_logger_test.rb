require "test_helper"
require "minitest/mock"

class SemanticLoggerInitializerTest < ActiveSupport::TestCase
  test "configures backtrace level for errors" do
    assert_equal :error, Rails.configuration.semantic_logger.backtrace_level
  end

  test "sets appropriate log level for test environment" do
    assert_equal :warn, Rails.configuration.log_level
  end

  test "includes SemanticLogger::Loggable in Active Record models" do
    # Create a temporary model to test
    temp_model = Class.new(ActiveRecord::Base) do
      self.table_name = "users"
    end

    assert temp_model.included_modules.include?(SemanticLogger::Loggable)
  end

  test "includes SemanticLogger::Loggable in Action Controller" do
    # Create a temporary controller to test
    temp_controller = Class.new(ActionController::Base)

    assert temp_controller.included_modules.include?(SemanticLogger::Loggable)
  end

  test "filters sensitive parameters" do
    # Rails filter_parameters may contain regexes or symbols
    # Let's test that our custom parameters were added
    filter_params = Rails.configuration.filter_parameters

    # Convert to string for easier testing
    filter_param_strings = filter_params.map(&:to_s).join(" ")

    # Check that our parameters are included in some form
    %w[password token api_key secret email auth_token access_token
      refresh_token client_secret authorization bearer].each do |param|
      assert filter_param_strings.include?(param), "Expected filter_parameters to include #{param}"
    end
  end

  test "sets default log level based on environment" do
    # In test environment, we expect debug level
    expected_level = Rails.env.production? ? :info : :debug
    assert_equal expected_level, SemanticLogger.default_level
  end

  test "ApplicationLogging module provides log_performance method" do
    test_class = Class.new do
      include ApplicationLogging
      include SemanticLogger::Loggable
    end

    instance = test_class.new
    assert_respond_to instance, :log_performance
  end

  test "ApplicationLogging module provides log_with_context method" do
    test_class = Class.new do
      include ApplicationLogging
      include SemanticLogger::Loggable
    end

    instance = test_class.new
    assert_respond_to instance, :log_with_context
  end

  test "controllers include SemanticLogger::Loggable module" do
    # This verifies that controllers have access to semantic logger methods
    controller_class = Class.new(ActionController::Base)

    assert controller_class.included_modules.include?(SemanticLogger::Loggable)
    assert controller_class.private_instance_methods.include?(:with_request_context)
  end
end
