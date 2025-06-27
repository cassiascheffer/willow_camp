require "test_helper"

module Blog
  class RobotsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user_one = users(:one)
      @user_two = users(:two)
      @post_one = posts(:one) # Published post by user_one
      @post_two = posts(:two) # Unpublished post by user_two
      @custom_domain_user = users(:custom_domain_user)
      @custom_domain_post = posts(:custom_domain_post)

      # Set up host headers for subdomain-based testing
      @user_one_host = {host: "#{@user_one.subdomain}.willow.camp"}
      @user_two_host = {host: "#{@user_two.subdomain}.willow.camp"}
      @nonexistent_host = {host: "nonexistent.willow.camp"}
      @custom_domain_host = {host: @custom_domain_user.custom_domain}
    end

    test "should get robots.txt for user one" do
      get robots_path(format: :txt), headers: @user_one_host
      assert_response :success
      assert_equal "text/plain", @response.media_type

      # Check robots.txt structure
      assert_match(/User-agent: \*/, @response.body)
      assert_match(/Allow: \//, @response.body)
      assert_match(/Disallow: \/dashboard\//, @response.body)
      assert_match(/Sitemap: /, @response.body)
    end

    test "should get robots.txt for user two" do
      get robots_path(format: :txt), headers: @user_two_host
      assert_response :success

      # Check robots.txt structure
      assert_match(/User-agent: \*/, @response.body)
      assert_match(/Allow: \//, @response.body)
    end

    test "should redirect to root_url when subdomain does not exist" do
      get robots_path(format: :txt), headers: @nonexistent_host
      assert_redirected_to root_url(subdomain: false)
    end

    test "should get robots.txt with custom domain" do
      get robots_path(format: :txt), headers: @custom_domain_host
      assert_response :success
      assert_equal "text/plain", @response.media_type
    end

    test "should redirect robots.txt from subdomain to custom domain" do
      get robots_path(format: :txt), headers: {host: "#{@custom_domain_user.subdomain}.willow.camp"}
      assert_redirected_to "https://#{@custom_domain_user.custom_domain}/robots.txt"
    end

    test "should not redirect when already on custom domain" do
      get robots_path(format: :txt), headers: @custom_domain_host
      assert_response :success
      # Should not be a redirect
      assert_not response.redirect?
    end

    test "should include sitemap URL in robots.txt" do
      get robots_path(format: :txt), headers: @user_one_host
      assert_response :success

      # Check that sitemap URL is included
      assert_match(/Sitemap: .*\/sitemap\.xml/, @response.body)
    end

    test "should disallow dashboard paths" do
      get robots_path(format: :txt), headers: @user_one_host
      assert_response :success

      # Check that dashboard paths are disallowed
      assert_match(/Disallow: \/dashboard\//, @response.body)
      assert_match(/Disallow: \/dashboard/, @response.body)
    end

    test "should disallow user authentication paths" do
      get robots_path(format: :txt), headers: @user_one_host
      assert_response :success

      # Check that user auth paths are disallowed
      assert_match(/Disallow: \/users\/login/, @response.body)
      assert_match(/Disallow: \/users\/logout/, @response.body)
      assert_match(/Disallow: \/users\/signup/, @response.body)
    end

    test "should allow public blog content paths" do
      get robots_path(format: :txt), headers: @user_one_host
      assert_response :success

      # Check that public blog paths are allowed
      assert_match(/Allow: \/tags/, @response.body)
      assert_match(/Allow: \/t\//, @response.body)
      assert_match(/Allow: \/posts\/rss/, @response.body)
    end

    test "should handle case insensitive custom domain" do
      get robots_path(format: :txt), headers: {host: @custom_domain_user.custom_domain}
      assert_response :success
    end

    test "should handle subdomain with willow.camp domain" do
      get robots_path(format: :txt), headers: {host: "#{@user_one.subdomain}.willow.camp"}
      assert_response :success
    end

    test "should return txt format by default" do
      get robots_path(format: :txt), headers: @user_one_host
      assert_response :success
      assert_equal "text/plain", @response.media_type
    end

    test "should include crawl delay directive" do
      get robots_path(format: :txt), headers: @user_one_host
      assert_response :success
      assert_match(/Crawl-delay: 1/, @response.body)
    end

    test "should include proper user agent directive" do
      get robots_path(format: :txt), headers: @user_one_host
      assert_response :success
      assert_match(/User-agent: \*/, @response.body)
    end

    test "should disallow API endpoints" do
      get robots_path(format: :txt), headers: @user_one_host
      assert_response :success
      assert_match(/Disallow: \/api\//, @response.body)
    end

    test "should disallow health check endpoint" do
      get robots_path(format: :txt), headers: @user_one_host
      assert_response :success
      assert_match(/Disallow: \/up/, @response.body)
    end
  end
end
