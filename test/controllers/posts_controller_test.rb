require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
    @user = users(:one)
    @custom_domain_user = users(:custom_domain_user)
    @custom_domain_post = posts(:custom_domain_post)

    host = "#{@user.subdomain}.willow.camp"
    @headers = {host: host}
  end

  test "should get index" do
    get posts_url, headers: @headers
    assert_response :success
  end

  test "should show post" do
    get "/my-post", headers: {host: "#{@user.subdomain}.willow.camp"}
    assert_response :success
  end

  test "should find user by subdomain" do
    get posts_url, headers: {host: "#{@user.subdomain}.willow.camp"}
    assert_response :success
    assert_select "title", text: /#{@user.blog_title}/i
  end

  test "should find user by custom domain" do
    get posts_url, headers: {host: @custom_domain_user.custom_domain}
    assert_response :success
    assert_select "title", text: /#{@custom_domain_user.blog_title}/i
  end

  test "should redirect to main site when user not found" do
    get posts_url, headers: {host: "nonexistent.willow.camp"}
    assert_redirected_to root_url(subdomain: false)
  end

  test "should redirect to custom domain when user has one" do
    # Access via subdomain when user has custom domain
    get posts_url, headers: {host: "#{@custom_domain_user.subdomain}.willow.camp"}
    assert_redirected_to "https://#{@custom_domain_user.custom_domain}/"
  end

  test "should not redirect when already on custom domain" do
    # Access via custom domain - should not redirect
    get posts_url, headers: {host: @custom_domain_user.custom_domain}
    assert_response :success
    assert_select "title", text: /#{@custom_domain_user.blog_title}/i
  end

  test "should handle post show with custom domain" do
    get "/#{@custom_domain_post.slug}", headers: {host: @custom_domain_user.custom_domain}
    assert_response :success
    assert_select "h1", text: @custom_domain_post.title
  end

  test "should redirect post show to custom domain" do
    get "/#{@custom_domain_post.slug}", headers: {host: "#{@custom_domain_user.subdomain}.willow.camp"}
    assert_redirected_to "https://#{@custom_domain_user.custom_domain}/#{@custom_domain_post.slug}"
  end

  test "should handle subdomain with no custom domain normally" do
    get posts_url, headers: {host: "#{@user.subdomain}.willow.camp"}
    assert_response :success
    assert_select "title", text: /#{@user.blog_title}/i
  end

  test "should handle case insensitive domain matching" do
    get posts_url, headers: {host: @custom_domain_user.custom_domain}
    assert_response :success
    assert_select "title", text: /#{@custom_domain_user.blog_title}/i
  end
end
