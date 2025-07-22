require "test_helper"

class WillowCampCliTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::WillowCampCLI::VERSION
  end

  def test_error_class_exists
    assert defined?(WillowCampCLI::Error)
    assert WillowCampCLI::Error.ancestors.include?(StandardError)
  end
end
