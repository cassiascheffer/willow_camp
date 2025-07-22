require "test_helper"

class DebugTest < Minitest::Test
  def test_exit_stub
    exit_mock = lambda { |code|
      puts "Exit called with code: #{code}"
      nil
    }

    Kernel.stub :exit, exit_mock do
      Kernel.exit(1)
    end

    assert true  # If we get here, the stub worked
  end
end
