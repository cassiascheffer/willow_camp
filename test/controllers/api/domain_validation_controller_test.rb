require "test_helper"

class Api::DomainValidationControllerTest < ActionDispatch::IntegrationTest
  def setup
    @blog_with_custom_domain = blogs(:custom_domain_blog)
    @blog_with_subdomain = blogs(:one)
  end

  test "validates willow.camp main domain" do
    get api_domain_validation_path, params: {domain: "willow.camp"}
    assert_response :ok
  end

  test "validates willow.camp subdomains" do
    get api_domain_validation_path, params: {domain: "test.willow.camp"}
    assert_response :ok

    get api_domain_validation_path, params: {domain: "blog.willow.camp"}
    assert_response :ok

    get api_domain_validation_path, params: {domain: "user123.willow.camp"}
    assert_response :ok
  end

  test "validates existing custom domain" do
    get api_domain_validation_path, params: {domain: @blog_with_custom_domain.custom_domain}
    assert_response :ok
  end

  test "rejects non-existent custom domain" do
    get api_domain_validation_path, params: {domain: "nonexistent.com"}
    assert_response :forbidden
  end

  test "rejects blank domain" do
    get api_domain_validation_path, params: {domain: ""}
    assert_response :forbidden

    get api_domain_validation_path, params: {domain: nil}
    assert_response :forbidden
  end

  test "validates domain from Host header when no domain param" do
    get api_domain_validation_path, headers: {"Host" => @blog_with_custom_domain.custom_domain}
    assert_response :ok
  end

  test "rejects invalid domain from Host header" do
    get api_domain_validation_path, headers: {"Host" => "invalid.com"}
    assert_response :forbidden
  end

  test "validates willow.camp domain from Host header" do
    get api_domain_validation_path, headers: {"Host" => "test.willow.camp"}
    assert_response :ok
  end

  test "handles multiple subdomains for willow.camp" do
    get api_domain_validation_path, params: {domain: "blog.user.willow.camp"}
    assert_response :ok
  end

  test "case insensitive domain validation" do
    get api_domain_validation_path, params: {domain: @blog_with_custom_domain.custom_domain.upcase}
    assert_response :ok

    get api_domain_validation_path, params: {domain: @blog_with_custom_domain.custom_domain.titleize}
    assert_response :ok
  end

  test "validates domain with different TLDs" do
    blog_org = blogs(:enumerator_blog)

    get api_domain_validation_path, params: {domain: blog_org.custom_domain}
    assert_response :ok
  end

  test "skips CSRF token verification" do
    # This test ensures the endpoint can be called by Caddy without CSRF token
    get api_domain_validation_path, params: {domain: @blog_with_custom_domain.custom_domain}
    # Should not raise ActionController::InvalidAuthenticityToken
    assert_response :ok # GET request should work
  end

  test "responds to GET requests only" do
    get api_domain_validation_path, params: {domain: @blog_with_custom_domain.custom_domain}
    assert_response :ok

    # Non-GET requests return 404 since the route doesn't exist for them
    post api_domain_validation_path, params: {domain: @blog_with_custom_domain.custom_domain}
    assert_response :not_found

    put api_domain_validation_path, params: {domain: @blog_with_custom_domain.custom_domain}
    assert_response :not_found

    delete api_domain_validation_path, params: {domain: @blog_with_custom_domain.custom_domain}
    assert_response :not_found
  end

  test "handles domain with port number" do
    get api_domain_validation_path, params: {domain: "#{@blog_with_custom_domain.custom_domain}:443"}
    # Should still validate the domain part
    assert_response :ok
  end

  test "handles malformed domains gracefully" do
    malformed_domains = [
      "..invalid.com",
      "invalid..com",
      ".invalid.com",
      "invalid.com.",
      "http://invalid.com",
      "invalid com",
      "invalid.com/path"
    ]

    malformed_domains.each do |domain|
      get api_domain_validation_path, params: {domain: domain}
      assert_response :forbidden, "Should reject malformed domain: #{domain}"
    end
  end
end
