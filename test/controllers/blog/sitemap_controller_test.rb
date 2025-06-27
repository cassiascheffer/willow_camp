require "test_helper"

module Blog
  class SitemapControllerTest < ActionDispatch::IntegrationTest
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

    test "should get sitemap for user one" do
      get sitemap_path(format: :xml), headers: @user_one_host
      assert_response :success
      assert_equal "application/xml", @response.media_type

      # Check sitemap structure
      assert_match(/<urlset.*xmlns="http:\/\/www\.sitemaps\.org\/schemas\/sitemap\/0\.9"/, @response.body)
      assert_match(/<url>/, @response.body)
      assert_match(/<loc>/, @response.body)
      assert_match(/<lastmod>/, @response.body)
      assert_match(/<changefreq>/, @response.body)
      assert_match(/<priority>/, @response.body)
    end

    test "should get sitemap for user two" do
      get sitemap_path(format: :xml), headers: @user_two_host
      assert_response :success

      # Check sitemap structure
      assert_match(/<urlset.*xmlns="http:\/\/www\.sitemaps\.org\/schemas\/sitemap\/0\.9"/, @response.body)
    end

    test "should redirect to root_url when subdomain does not exist" do
      get sitemap_path(format: :xml), headers: @nonexistent_host
      assert_redirected_to root_url(subdomain: false)
    end

    test "should only show published posts in sitemap" do
      get sitemap_path(format: :xml), headers: @user_one_host
      assert_response :success
      # Should not include unpublished posts from other users
      assert_not_includes @response.body, @post_two.title
    end

    test "should get sitemap with custom domain" do
      get sitemap_path(format: :xml), headers: @custom_domain_host
      assert_response :success
      assert_equal "application/xml", @response.media_type
    end

    test "should redirect sitemap from subdomain to custom domain" do
      get sitemap_path(format: :xml), headers: {host: "#{@custom_domain_user.subdomain}.willow.camp"}
      assert_redirected_to "https://#{@custom_domain_user.custom_domain}/sitemap.xml"
    end

    test "should not redirect when already on custom domain" do
      get sitemap_path(format: :xml), headers: @custom_domain_host
      assert_response :success
      # Should not be a redirect
      assert_not response.redirect?
    end

    test "should include home page in sitemap" do
      get sitemap_path(format: :xml), headers: @user_one_host
      assert_response :success

      # Check that home page URL is included
      assert_match(/<loc>.*<\/loc>/, @response.body)
    end

    test "should include individual post URLs in sitemap" do
      get sitemap_path(format: :xml), headers: @user_one_host
      assert_response :success

      # Check that individual post URLs are included
      assert_match(/<loc>.*<\/loc>/, @response.body)
    end

    test "should handle case insensitive custom domain" do
      get sitemap_path(format: :xml), headers: {host: @custom_domain_user.custom_domain}
      assert_response :success
    end

    test "should handle subdomain with willow.camp domain" do
      get sitemap_path(format: :xml), headers: {host: "#{@user_one.subdomain}.willow.camp"}
      assert_response :success
    end

    test "should return XML format by default" do
      get sitemap_path(format: :xml), headers: @user_one_host
      assert_response :success
      assert_equal "application/xml", @response.media_type
    end

    test "should include proper XML declaration" do
      get sitemap_path(format: :xml), headers: @user_one_host
      assert_response :success
      assert_match(/<\?xml version="1\.0" encoding="UTF-8"\?>/, @response.body)
    end
  end
end
