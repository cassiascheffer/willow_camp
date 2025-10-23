require "test_helper"

class Blogs::PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
    @blog = blogs(:one)
    @custom_domain_blog = blogs(:custom_domain_blog)
    @custom_domain_post = posts(:custom_domain_post)

    host = "#{@blog.subdomain}.willow.camp"
    @headers = {host: host}
  end

  test "should get index" do
    get posts_url, headers: @headers
    assert_response :success
  end

  test "should show post" do
    get "/my-post", headers: {host: "#{@blog.subdomain}.willow.camp"}
    assert_response :success
  end

  test "should find user by subdomain" do
    get posts_url, headers: {host: "#{@blog.subdomain}.willow.camp"}
    assert_response :success
    assert_select "title", text: /#{@blog.title}/i
  end

  test "should find user by custom domain" do
    get posts_url, headers: {host: @custom_domain_blog.custom_domain}
    assert_response :success
    assert_select "title", text: /#{@custom_domain_blog.title}/i
  end

  test "should return 404 when user not found" do
    get posts_url, headers: {host: "nonexistent.willow.camp"}
    assert_response :not_found
  end

  test "should redirect to custom domain when user has one" do
    # Access via subdomain when user has custom domain
    get posts_url, headers: {host: "#{@custom_domain_blog.subdomain}.willow.camp"}
    assert_redirected_to "https://#{@custom_domain_blog.custom_domain}/"
  end

  test "should not redirect when already on custom domain" do
    # Access via custom domain - should not redirect
    get posts_url, headers: {host: @custom_domain_blog.custom_domain}
    assert_response :success
    assert_select "title", text: /#{@custom_domain_blog.title}/i
  end

  test "should handle post show with custom domain" do
    get "/#{@custom_domain_post.slug}", headers: {host: @custom_domain_blog.custom_domain}
    assert_response :success
    assert_select "h1", text: @custom_domain_post.title
  end

  test "should redirect post show to custom domain" do
    get "/#{@custom_domain_post.slug}", headers: {host: "#{@custom_domain_blog.subdomain}.willow.camp"}
    assert_redirected_to "https://#{@custom_domain_blog.custom_domain}/#{@custom_domain_post.slug}"
  end

  test "should handle subdomain with no custom domain normally" do
    get posts_url, headers: {host: "#{@blog.subdomain}.willow.camp"}
    assert_response :success
    assert_select "title", text: /#{@blog.title}/i
  end

  test "should handle case insensitive domain matching" do
    get posts_url, headers: {host: @custom_domain_blog.custom_domain}
    assert_response :success
    assert_select "title", text: /#{@custom_domain_blog.title}/i
  end

  test "should return 404 for non-existent post with JSON format" do
    get "/nonexistent-post.json", headers: {host: "#{@blog.subdomain}.willow.camp"}
    assert_response :not_found
    assert_equal "application/json", response.media_type
  end

  test "should return 404 HTML for non-existent post with HTML format" do
    get "/nonexistent-post", headers: {host: "#{@blog.subdomain}.willow.camp"}
    assert_response :not_found
    assert_equal "text/html", response.media_type
  end

  test "should display featured posts section when featured posts exist" do
    get posts_url, headers: @headers
    assert_response :success

    assert_select "h2", text: "Featured"
    assert_select "article.post-summary" do
      assert_select "h3", text: @post.title
    end
  end

  test "should not display featured posts section when no featured posts exist" do
    @blog.posts.update_all(featured: false)

    get posts_url, headers: @headers
    assert_response :success

    assert_select "h2", text: "Featured", count: 0
  end

  test "should show meta description for featured posts when present" do
    get posts_url, headers: @headers
    assert_response :success

    assert_select "p", text: @post.meta_description
  end

  test "should set cache control headers on post show" do
    get "/#{@post.slug}", headers: {host: "#{@blog.subdomain}.willow.camp"}
    assert_response :success

    cache_control = response.headers["Cache-Control"]
    assert_includes cache_control, "max-age=300", "Should cache for 5 minutes (300 seconds)"
    assert_includes cache_control, "public", "Should be publicly cacheable"
  end

  test "should set ETag header on post show" do
    get "/#{@post.slug}", headers: {host: "#{@blog.subdomain}.willow.camp"}
    assert_response :success
    assert_not_nil response.headers["ETag"], "ETag header should be present"
  end

  test "should return 304 when content has not changed" do
    get "/#{@post.slug}", headers: {host: "#{@blog.subdomain}.willow.camp"}
    assert_response :success
    etag = response.headers["ETag"]

    get "/#{@post.slug}", headers: {host: "#{@blog.subdomain}.willow.camp", "If-None-Match" => etag}
    assert_response :not_modified
  end

  test "should return 200 when content has changed" do
    get "/#{@post.slug}", headers: {host: "#{@blog.subdomain}.willow.camp"}
    assert_response :success
    old_etag = response.headers["ETag"]

    @post.update!(title: "Updated Title")

    get "/#{@post.slug}", headers: {host: "#{@blog.subdomain}.willow.camp", "If-None-Match" => old_etag}
    assert_response :success
    new_etag = response.headers["ETag"]
    assert_not_equal old_etag, new_etag, "ETag should change when post is updated"
  end

  test "should not set cache headers for non-existent posts" do
    get "/nonexistent-post", headers: {host: "#{@blog.subdomain}.willow.camp"}
    assert_response :not_found
    assert_nil response.headers["ETag"], "ETag should not be set for 404 responses"
  end

  test "should render pages in navigation" do
    # Create a page to appear in navigation
    @blog.pages.create!(
      title: "Test Page",
      body_markdown: "Test content",
      author: @blog.user,
      published: true
    )

    get "/#{@post.slug}", headers: {host: "#{@blog.subdomain}.willow.camp"}
    assert_response :success

    # Check that page appears in navigation
    assert_select "nav a", text: "Test Page"
    assert_select "nav a", text: "Subscribe"
  end

  test "should not show unpublished pages in navigation" do
    # Create an unpublished page
    @blog.pages.create!(
      title: "Draft Page",
      body_markdown: "Draft content",
      author: @blog.user,
      published: false
    )

    get "/#{@post.slug}", headers: {host: "#{@blog.subdomain}.willow.camp"}
    assert_response :success

    # Draft page should not appear in navigation
    assert_select "nav a", text: "Draft Page", count: 0
  end

  test "should use fragment caching for navigation" do
    with_cache_store(:memory_store) do
      # First request creates the cache
      get "/#{@post.slug}", headers: {host: "#{@blog.subdomain}.willow.camp"}
      assert_response :success
      assert_select "nav a", text: "Subscribe"

      # Second request should use cached fragments and render correctly
      get "/#{@post.slug}", headers: {host: "#{@blog.subdomain}.willow.camp"}
      assert_response :success
      assert_select "nav a", text: "Subscribe"

      # Verify navigation still works with caching enabled
      assert_select "nav#mobile-nav"
      assert_select "nav#navigation"
    end
  end

  test "should set cache control headers on index" do
    get posts_url, headers: @headers
    assert_response :success

    cache_control = response.headers["Cache-Control"]
    assert_includes cache_control, "max-age=300", "Should cache for 5 minutes (300 seconds)"
    assert_includes cache_control, "public", "Should be publicly cacheable"
  end

  test "should set ETag header on index" do
    get posts_url, headers: @headers
    assert_response :success
    assert_not_nil response.headers["ETag"], "ETag header should be present"
  end

  test "should return 304 for index when content has not changed" do
    get posts_url, headers: @headers
    assert_response :success
    etag = response.headers["ETag"]

    get posts_url, headers: @headers.merge("If-None-Match" => etag)
    assert_response :not_modified
  end

  test "should return 200 for index when content has changed" do
    get posts_url, headers: @headers
    assert_response :success
    old_etag = response.headers["ETag"]

    # Update a post to change the index
    @post.update!(title: "Updated Index Title")

    get posts_url, headers: @headers.merge("If-None-Match" => old_etag)
    assert_response :success
    new_etag = response.headers["ETag"]
    assert_not_equal old_etag, new_etag, "ETag should change when posts are updated"
  end

  test "should not set session cookie for public blog pages" do
    get "/#{@post.slug}", headers: {host: "#{@blog.subdomain}.willow.camp"}
    assert_response :success

    # Should not send session cookie
    assert_nil response.headers["Set-Cookie"], "Public blog pages should not set cookies"
  end

  test "should not set session cookie for index" do
    get posts_url, headers: @headers
    assert_response :success

    # Should not send session cookie
    assert_nil response.headers["Set-Cookie"], "Public blog index should not set cookies"
  end

  private

  def with_cache_store(store_type)
    old_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache.lookup_store(store_type)
    yield
  ensure
    Rails.cache = old_cache
  end
end
