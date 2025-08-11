require "test_helper"

class SecureDomainRedirectTest < ActionController::TestCase
  # Create a test controller that includes the concern
  class TestController < ApplicationController
    include SecureDomainRedirect

    def index
      render plain: "OK"
    end

    # Expose private methods for testing
    def test_valid_redirect_domain?(domain)
      valid_redirect_domain?(domain)
    end

    def test_sanitize_redirect_path(path)
      sanitize_redirect_path(path)
    end

    def test_build_secure_redirect_url(domain, path)
      build_secure_redirect_url(domain, path)
    end
  end

  def setup
    @controller = TestController.new
    @user = users(:custom_domain_user)
  end

  test "valid_redirect_domain? accepts valid domains" do
    valid_domains = [
      "example.com",
      "subdomain.example.com",
      "test-site.org",
      "my-blog.co.uk",
      "example123.net"
    ]

    valid_domains.each do |domain|
      assert @controller.test_valid_redirect_domain?(domain),
        "Expected '#{domain}' to be valid"
    end
  end

  test "valid_redirect_domain? rejects dangerous domains" do
    invalid_domains = [
      "localhost",
      "127.0.0.1",
      "0.0.0.0",
      "::1",
      "192.168.1.1",
      "[::1]",
      "test.willow.camp",
      "willow.camp",
      "",
      nil,
      "invalid domain with spaces",
      "domain_with_underscores.com",
      "a" * 254, # Too long
      "invalid..domain.com",
      ".invalid.com",
      "invalid.com.",
      "http://example.com"
    ]

    invalid_domains.each do |domain|
      assert_not @controller.test_valid_redirect_domain?(domain),
        "Expected '#{domain}' to be invalid"
    end
  end

  test "sanitize_redirect_path handles various inputs" do
    test_cases = {
      nil => "/",
      "" => "/",
      "/valid/path" => "/valid/path",
      "path/without/leading/slash" => "/path/without/leading/slash",
      "/path/with\x00null\x01bytes" => "/path/withnullbytes",
      "/path/with/../traversal" => "/path/with/../traversal", # Note: we don't handle traversal, just dangerous chars
      "a" * 3000 => "/" + "a" * 2047, # Truncated to 2048 chars
      "/normal/path?query=value&other=test" => "/normal/path?query=value&other=test"
    }

    test_cases.each do |input, expected|
      result = @controller.test_sanitize_redirect_path(input)
      assert_equal expected, result,
        "Expected sanitize_redirect_path('#{input}') to return '#{expected}', got '#{result}'"
    end
  end

  test "build_secure_redirect_url constructs HTTPS URLs" do
    domain = "example.com"
    path = "/blog/post"

    result = @controller.test_build_secure_redirect_url(domain, path)
    expected = "https://example.com/blog/post"

    assert_equal expected, result
  end

  test "build_secure_redirect_url handles empty paths" do
    domain = "example.com"
    path = ""

    result = @controller.test_build_secure_redirect_url(domain, path)
    expected = "https://example.com/"

    assert_equal expected, result
  end

  test "build_secure_redirect_url sanitizes paths" do
    domain = "example.com"
    path = "/blog\x00/post"

    result = @controller.test_build_secure_redirect_url(domain, path)
    expected = "https://example.com/blog/post"

    assert_equal expected, result
  end
end

class SecureDomainRedirectIntegrationTest < ActionDispatch::IntegrationTest
  def setup
    @user_with_custom_domain = users(:custom_domain_user)
    @user_with_subdomain = users(:one)
  end

  test "redirects to custom domain when appropriate" do
    # Simulate request to subdomain when user has custom domain
    host! "#{@user_with_custom_domain.subdomain}.willow.camp"

    get posts_path

    assert_response :moved_permanently
    assert_redirected_to "https://#{@user_with_custom_domain.custom_domain}#{posts_path}"
  end

  test "does not redirect when already on custom domain" do
    # Simulate request directly to custom domain
    host! @user_with_custom_domain.custom_domain

    get posts_path

    assert_response :success
  end

  test "handles users without custom domains normally" do
    host! "#{@user_with_subdomain.subdomain}.willow.camp"

    get posts_path

    assert_response :success
  end

  test "returns 404 for non-existent subdomain" do
    # Request to a subdomain that doesn't exist
    host! "nonexistentblog.willow.camp"

    get posts_path

    assert_response :not_found
    # Verify the 404 page content is rendered
    assert_match(/Page Not Found/, response.body)
    assert_match(/404/, response.body)
  end

  test "returns 404 for reserved word subdomain" do
    # Request to a reserved word subdomain (like 'admin')
    host! "admin.willow.camp"

    get posts_path

    assert_response :not_found
    assert_match(/Page Not Found/, response.body)
  end

  test "does not redirect to root for non-existent subdomain" do
    # Ensure we're not redirecting, but returning 404 directly
    host! "fakeblog.willow.camp"

    get posts_path

    assert_response :not_found
    assert_not_equal root_url(subdomain: false), response.location
    assert_nil response.location
  end
end
