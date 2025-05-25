require "test_helper"

module Posts
  class FeedControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user_one = users(:one)
      @user_two = users(:two)
      @post_one = posts(:one) # Published post by user_one
      @post_two = posts(:two) # Unpublished post by user_two

      # Create another published post for user_two to test author filtering
      @published_post_by_user_two = Post.create!(
        title: "Published Post by User Two",
        body_markdown: "# Test Content\n\nThis is test content.",
        body_html: "<h1>Test Content</h1>\n<p>This is test content.</p>",
        author: @user_two,
        published: true,
        published_at: Time.current,
        slug: "published-by-user-two"
      )

      # Set up host headers for subdomain-based testing
      @user_one_host = {host: "#{@user_one.subdomain}.example.com"}
      @user_two_host = {host: "#{@user_two.subdomain}.example.com"}
      @nonexistent_host = {host: "nonexistent.example.com"}
    end

    test "should get atom feed for user one" do
      get "/posts/atom", headers: @user_one_host
      assert_response :success
      assert_equal "application/atom+xml", @response.media_type

      # Check that feed contains only user_one's post
      assert_includes @response.body, @post_one.title
      assert_not_includes @response.body, @published_post_by_user_two.title

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
      assert_not_includes @response.body, @published_post_by_user_two.title

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
      assert_not_includes post_titles, @published_post_by_user_two.title

      # Check feed structure
      assert_equal "https://jsonfeed.org/version/1.1", json_response["version"]
      assert json_response["items"].is_a?(Array)
      assert json_response["items"].first.key?("content_html")
    end

    test "should get atom feed for user two" do
      get "/posts/atom", headers: @user_two_host
      assert_response :success

      # Check that feed contains only user_two's published post
      assert_includes @response.body, @published_post_by_user_two.title
      assert_not_includes @response.body, @post_one.title
      assert_not_includes @response.body, @post_two.title # unpublished post
    end

    test "should get rss feed for user two" do
      get "/posts/rss", headers: @user_two_host
      assert_response :success

      # Check that feed contains only user_two's published post
      assert_includes @response.body, @published_post_by_user_two.title
      assert_not_includes @response.body, @post_one.title
      assert_not_includes @response.body, @post_two.title # unpublished post
    end

    test "should get json feed for user two" do
      get "/posts/json", headers: @user_two_host
      assert_response :success

      # Parse the JSON response
      json_response = JSON.parse(@response.body)

      # Check that feed contains only user_two's published post
      post_titles = json_response["items"].map { |item| item["title"] }
      assert_includes post_titles, @published_post_by_user_two.title
      assert_not_includes post_titles, @post_one.title
      assert_not_includes post_titles, @post_two.title # unpublished post
    end

    test "should redirect to root_url when subdomain does not exist" do
      get "/posts/atom", headers: @nonexistent_host
      assert_redirected_to root_url(subdomain: false)
    end

    test "should only show published posts" do
      # User two has both published and unpublished posts

      # Test for atom format
      get "/posts/atom", headers: @user_two_host
      assert_response :success
      assert_includes @response.body, @published_post_by_user_two.title
      assert_not_includes @response.body, @post_two.title # This post is unpublished

      # Test for rss format
      get "/posts/rss", headers: @user_two_host
      assert_response :success
      assert_includes @response.body, @published_post_by_user_two.title
      assert_not_includes @response.body, @post_two.title # This post is unpublished

      # Test for json format
      get "/posts/json", headers: @user_two_host
      assert_response :success
      json_response = JSON.parse(@response.body)
      post_titles = json_response["items"].map { |item| item["title"] }
      assert_includes post_titles, @published_post_by_user_two.title
      assert_not_includes post_titles, @post_two.title # This post is unpublished
    end
  end
end
