require "test_helper"

module Blog
  class FeedControllerTest < ActionDispatch::IntegrationTest
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

    test "should get atom feed for user one" do
      get "/posts/atom", headers: @user_one_host
      assert_response :success
      assert_equal "application/atom+xml", @response.media_type

      # Check that feed contains only user_one's post
      assert_includes @response.body, @post_one.title

      # Check feed structure
      assert_match(/<feed.*xmlns="http:\/\/www\.w3\.org\/2005\/Atom"/, @response.body)
      assert_match(/<title>.*<\/title>/, @response.body)
      assert_match(/<link.*rel="self".*type="application\/atom\+xml"/, @response.body)
    end

    test "should get rss feed for user one" do
      get "/posts/rss", headers: @user_one_host
      assert_response :success
      assert_equal "application/rss+xml", @response.media_type

      # Check that feed contains only user_one's post
      assert_includes @response.body, @post_one.title

      # Check feed structure
      assert_match(/<rss.*version="2\.0"/, @response.body)
      assert_match(/<channel>/, @response.body)
      assert_match(/<item>/, @response.body)
    end

    test "should get json feed for user one" do
      get "/posts/json", headers: @user_one_host
      assert_response :success
      assert_equal "application/json", @response.media_type

      # Parse the JSON response
      json_response = JSON.parse(@response.body)

      # Check that feed contains only user_one's post
      post_titles = json_response["items"].map { |item| item["title"] }
      assert_includes post_titles, @post_one.title

      # Check feed structure
      assert_equal "https://jsonfeed.org/version/1.1", json_response["version"]
      assert json_response["items"].is_a?(Array)
      assert json_response["items"].first.key?("content_html")
    end

    test "should get atom feed for user two" do
      get "/posts/atom", headers: @user_two_host
      assert_response :success

      # Check feed structure
      assert_match(/<feed.*xmlns="http:\/\/www\.w3\.org\/2005\/Atom"/, @response.body)
    end

    test "should get rss feed for user two" do
      get "/posts/rss", headers: @user_two_host
      assert_response :success

      # Check feed structure
      assert_match(/<rss.*version="2\.0"/, @response.body)
    end

    test "should get json feed for user two" do
      get "/posts/json", headers: @user_two_host
      assert_response :success

      # Parse the JSON response
      json_response = JSON.parse(@response.body)

      # Check feed structure
      assert_equal "https://jsonfeed.org/version/1.1", json_response["version"]
      assert json_response["items"].is_a?(Array)
    end

    test "should redirect to root_url when subdomain does not exist" do
      get "/posts/atom", headers: @nonexistent_host
      assert_redirected_to root_url(subdomain: false)
    end

    test "should only show published posts" do
      # Test for atom format
      get "/posts/atom", headers: @user_one_host
      assert_response :success
      assert_includes @response.body, @post_one.title

      # Test for rss format
      get "/posts/rss", headers: @user_one_host
      assert_response :success
      assert_includes @response.body, @post_one.title

      # Test for json format
      get "/posts/json", headers: @user_one_host
      assert_response :success
      json_response = JSON.parse(@response.body)
      post_titles = json_response["items"].map { |item| item["title"] }
      assert_includes post_titles, @post_one.title
    end

    test "should get atom feed with custom domain" do
      get "/posts/atom", headers: @custom_domain_host
      assert_response :success
      assert_equal "application/atom+xml", @response.media_type

      # Check that feed contains only custom domain user's post
      assert_includes @response.body, @custom_domain_post.title
    end

    test "should get rss feed with custom domain" do
      get "/posts/rss", headers: @custom_domain_host
      assert_response :success
      assert_equal "application/rss+xml", @response.media_type

      # Check that feed contains only custom domain user's post
      assert_includes @response.body, @custom_domain_post.title
    end

    test "should get json feed with custom domain" do
      get "/posts/json", headers: @custom_domain_host
      assert_response :success
      assert_equal "application/json", @response.media_type

      # Parse the JSON response
      json_response = JSON.parse(@response.body)

      # Check that feed contains only custom domain user's post
      post_titles = json_response["items"].map { |item| item["title"] }
      assert_includes post_titles, @custom_domain_post.title
    end

    test "should redirect atom feed from subdomain to custom domain" do
      get "/posts/atom", headers: {host: "#{@custom_domain_user.subdomain}.willow.camp"}
      assert_redirected_to "https://#{@custom_domain_user.custom_domain}/posts/atom"
    end

    test "should redirect rss feed from subdomain to custom domain" do
      get "/posts/rss", headers: {host: "#{@custom_domain_user.subdomain}.willow.camp"}
      assert_redirected_to "https://#{@custom_domain_user.custom_domain}/posts/rss"
    end

    test "should redirect json feed from subdomain to custom domain" do
      get "/posts/json", headers: {host: "#{@custom_domain_user.subdomain}.willow.camp"}
      assert_redirected_to "https://#{@custom_domain_user.custom_domain}/posts/json"
    end

    test "should not redirect when already on custom domain" do
      get "/posts/atom", headers: @custom_domain_host
      assert_response :success
      # Should not be a redirect
      assert_not response.redirect?
    end

    test "should handle case insensitive custom domain" do
      get "/posts/atom", headers: {host: @custom_domain_user.custom_domain}
      assert_response :success
      assert_includes @response.body, @custom_domain_post.title
    end

    test "should handle subdomain with willow.camp domain" do
      get "/posts/atom", headers: {host: "#{@user_one.subdomain}.willow.camp"}
      assert_response :success
      assert_includes @response.body, @post_one.title
    end
  end
end
