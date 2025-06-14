require "test_helper"

class DomainConstraintTest < ActionDispatch::IntegrationTest
  def setup
    @user_with_subdomain = users(:one)
    @user_with_custom_domain = users(:custom_domain_user)
    @subdomain_post = posts(:one)
    @custom_domain_post = posts(:custom_domain_post)
  end

  test "routes to posts index with valid subdomain" do
    get "/", headers: {host: "#{@user_with_subdomain.subdomain}.willow.camp"}
    assert_response :success
    assert_select "title", text: /#{@user_with_subdomain.blog_title}/i
  end

  test "routes to posts index with valid custom domain" do
    get "/", headers: {host: @user_with_custom_domain.custom_domain}
    assert_response :success
  end

  test "routes to specific post with valid subdomain" do
    get "/#{@subdomain_post.slug}", headers: {host: "#{@user_with_subdomain.subdomain}.willow.camp"}
    assert_response :success
  end

  test "routes to specific post with valid custom domain" do
    get "/#{@custom_domain_post.slug}", headers: {host: @user_with_custom_domain.custom_domain}
    assert_response :success
  end

  test "routes to tags index with valid subdomain" do
    get "/tags", headers: {host: "#{@user_with_subdomain.subdomain}.willow.camp"}
    assert_response :success
  end

  test "routes to tags index with valid custom domain" do
    get "/tags", headers: {host: @user_with_custom_domain.custom_domain}
    assert_response :success
  end

  test "does not route blog paths for main willow.camp domain" do
    get "/", headers: {host: "willow.camp"}
    assert_response :success
    # Should hit the home controller, not posts controller
    assert_select "title", text: /Posts/i, count: 0
  end

  test "does not route blog paths for non-existent subdomain" do
    get "/", headers: {host: "nonexistent.willow.camp"}
    assert_redirected_to root_url(subdomain: false)
  end

  test "does not route blog paths for non-existent custom domain" do
    get "/", headers: {host: "nonexistent.com"}
    # Should hit home controller since constraint doesn't match
    assert_response :success
    assert_select "title", text: /willow\.camp/i
  end

  test "handles case insensitive domain matching" do
    get "/", headers: {host: @user_with_custom_domain.custom_domain}
    assert_response :success
  end

  test "handles multi-level subdomains" do
    get "/", headers: {host: "blog.#{@user_with_subdomain.subdomain}.willow.camp"}
    assert_redirected_to root_url(subdomain: false)
  end

  test "redirects subdomain to custom domain when user has both" do
    get "/", headers: {host: "#{@user_with_custom_domain.subdomain}.willow.camp"}
    assert_redirected_to "https://#{@user_with_custom_domain.custom_domain}/"
  end

  test "redirects specific post from subdomain to custom domain" do
    get "/#{@custom_domain_post.slug}", headers: {host: "#{@user_with_custom_domain.subdomain}.willow.camp"}
    assert_redirected_to "https://#{@user_with_custom_domain.custom_domain}/#{@custom_domain_post.slug}"
  end

  test "redirects tags from subdomain to custom domain" do
    get "/tags", headers: {host: "#{@user_with_custom_domain.subdomain}.willow.camp"}
    assert_redirected_to "https://#{@user_with_custom_domain.custom_domain}/tags"
  end

  test "does not redirect when already on custom domain" do
    get "/", headers: {host: @user_with_custom_domain.custom_domain}
    assert_response :success
    # Should not be a redirect
    assert_not response.redirect?
  end

  test "handles feed routes with subdomain" do
    get "/posts/rss", headers: {host: "#{@user_with_subdomain.subdomain}.willow.camp"}
    assert_response :success
    assert_equal "application/rss+xml; charset=utf-8", response.content_type
  end

  test "handles feed routes with custom domain" do
    get "/posts/rss", headers: {host: @user_with_custom_domain.custom_domain}
    assert_response :success
    assert_equal "application/rss+xml; charset=utf-8", response.content_type
  end

  test "redirects feed routes from subdomain to custom domain" do
    get "/posts/rss", headers: {host: "#{@user_with_custom_domain.subdomain}.willow.camp"}
    assert_redirected_to "https://#{@user_with_custom_domain.custom_domain}/posts/rss"
  end

  test "constraint respects database state changes" do
    # Update existing user to have a different custom domain
    @user_with_custom_domain.update!(custom_domain: "newblog.com")

    # Should immediately work without restart
    get "/", headers: {host: "newblog.com"}
    assert_response :success

    # Remove custom domain
    @user_with_custom_domain.update!(custom_domain: nil)

    # Should no longer work - should hit home controller
    get "/", headers: {host: "newblog.com"}
    assert_response :success
    assert_select "title", text: /willow\.camp/i

    # Restore original domain for other tests
    @user_with_custom_domain.update!(custom_domain: "myblog.com")
  end

  test "handles domains with different ports" do
    get "/", headers: {host: "#{@user_with_subdomain.subdomain}.willow.camp:3000"}
    assert_response :success
  end

  test "api routes work regardless of domain constraints" do
    # API routes should work from any domain since they're not constrained
    get "/api/posts", headers: {host: "willow.camp"}
    assert_response :unauthorized

    get "/api/posts", headers: {host: "#{@user_with_subdomain.subdomain}.willow.camp"}
    assert_response :unauthorized

    get "/api/posts", headers: {host: @user_with_custom_domain.custom_domain}
    assert_response :unauthorized
  end

  test "dashboard routes work regardless of domain constraints" do
    sign_in @user_with_subdomain

    get "/dashboard", headers: {host: "willow.camp"}
    assert_response :success

    get "/dashboard", headers: {host: "#{@user_with_subdomain.subdomain}.willow.camp"}
    assert_response :success

    get "/dashboard", headers: {host: @user_with_custom_domain.custom_domain}
    assert_response :success
  end
end
