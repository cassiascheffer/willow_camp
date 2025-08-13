# Load general Rails system test configuration
require "application_system_test_case"

# Load configuration files and helpers
Dir[File.join(__dir__, "support/**/*.rb")].sort.each { |file| require file }
