# Precompile assets before running tests to avoid timeouts.
# Do not precompile if webpack-dev-server is running (NOTE: MUST be launched with RAILS_ENV=test)

module PrecompileAssets
  def self.setup
    # Check if we're running system tests by looking at the test files being loaded
    running_system_tests = caller.any? { |line| line.include?("test/system") } ||
      ARGV.any? { |arg| arg.include?("test/system") } ||
      ENV["RAILS_TEST_TYPE"] == "system"

    unless running_system_tests
      puts "\n🚀️️  No system test selected. Skip assets compilation.\n"
      return
    end

    puts "\n🐢  Precompiling assets.\n"
    original_stdout = $stdout.clone

    start = Time.current
    begin
      $stdout.reopen(File.new(File::Constants::NULL, "w"))

      require "rake"
      Rails.application.load_tasks
      Rake::Task["assets:precompile"].invoke
    ensure
      $stdout.reopen(original_stdout)
      puts "Finished in #{(Time.current - start).round(2)} seconds"
    end
  end
end

# Run the setup when this file is loaded
PrecompileAssets.setup if defined?(Rails)
