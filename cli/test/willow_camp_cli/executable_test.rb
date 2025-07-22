require "test_helper"

class WillowCampCliExecutableTest < Minitest::Test
  def test_executable_exists
    assert File.exist?(File.expand_path("../../../exe/willow-camp", __FILE__))
    assert File.executable?(File.expand_path("../../../exe/willow-camp", __FILE__))
  end

  def test_executable_loads_library
    executable_path = File.expand_path("../../../exe/willow-camp", __FILE__)
    content = File.read(executable_path)

    # Test that the executable attempts to load the library
    assert_match(/require ["']willow_camp_cli["']/, content)

    # Test that it calls the CLI run method
    assert_match(/WillowCampCLI::CLI\.run\(ARGV\)/, content)
  end
end
