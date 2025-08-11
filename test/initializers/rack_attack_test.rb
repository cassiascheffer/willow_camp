require "test_helper"

class RackAttackTest < ActiveSupport::TestCase
  test "extract_subdomain returns subdomain for willow.camp domains" do
    assert_equal "admin", Rack::Attack.extract_subdomain("admin.willow.camp")
    assert_equal "blog", Rack::Attack.extract_subdomain("blog.willow.camp")
    assert_equal "test-user", Rack::Attack.extract_subdomain("test-user.willow.camp")
  end

  test "extract_subdomain returns subdomain for localhost domains" do
    assert_equal "admin", Rack::Attack.extract_subdomain("admin.localhost")
    assert_equal "blog", Rack::Attack.extract_subdomain("blog.localhost")
    assert_equal "test-user", Rack::Attack.extract_subdomain("test-user.localhost")
  end

  test "extract_subdomain handles domains with ports" do
    assert_equal "admin", Rack::Attack.extract_subdomain("admin.localhost:3000")
    assert_equal "blog", Rack::Attack.extract_subdomain("blog.willow.camp:8080")
  end

  test "extract_subdomain returns nil for base domains" do
    assert_nil Rack::Attack.extract_subdomain("willow.camp")
    assert_nil Rack::Attack.extract_subdomain("localhost")
    assert_nil Rack::Attack.extract_subdomain("localhost:3000")
    assert_nil Rack::Attack.extract_subdomain("willow.camp:8080")
  end

  test "extract_subdomain returns nil for custom domains" do
    assert_nil Rack::Attack.extract_subdomain("example.com")
    assert_nil Rack::Attack.extract_subdomain("blog.example.com")
    assert_nil Rack::Attack.extract_subdomain("example.org:3000")
  end

  test "extract_subdomain returns nil for empty or invalid input" do
    assert_nil Rack::Attack.extract_subdomain("")
    assert_nil Rack::Attack.extract_subdomain(nil)
  end
end

class RackAttackIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    # Use memory store for testing throttles
    @original_cache_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    
    # Clear the cache before each test
    Rails.cache.clear
    Rack::Attack.reset!
  end
  
  teardown do
    # Restore original cache store
    Rack::Attack.cache.store = @original_cache_store
  end

  test "allows normal requests to existing blogs" do
    user = users(:one)
    host! "#{user.subdomain}.willow.camp"
    
    10.times do
      get "/"
      assert_response :success
    end
  end

  test "reserved subdomains return 404" do
    # Reserved subdomains should return 404 from the controller
    %w[admin api portal].each do |reserved|
      host! "#{reserved}.willow.camp"
      get "/"
      assert_response :not_found, "Reserved subdomain '#{reserved}' should return 404"
    end
  end

  test "non-existent subdomains return 404" do
    # Non-existent subdomains should return 404
    host! "doesnotexist.willow.camp"
    get "/"
    assert_response :not_found, "Non-existent subdomain should return 404"
  end

end