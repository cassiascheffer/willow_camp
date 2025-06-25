require "test_helper"

class Blog::TagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @post = posts(:one)
    @custom_domain_user = users(:custom_domain_user)
    @custom_domain_post = posts(:custom_domain_post)

    # Create a test tag with spaces
    @tag = ActsAsTaggableOn::Tag.create!(name: "Test Tag With Spaces")
    # Tag the posts
    @post.tag_list.add(@tag.name)
    @post.save
    @custom_domain_post.tag_list.add(@tag.name)
    @custom_domain_post.save

    # Set up host headers for subdomain-based testing
    @headers = {host: "#{@user.subdomain}.example.com"}
  end

  test "should get index" do
    get tags_url, headers: {host: "#{@user.subdomain}.willow.camp"}
    assert_response :success
  end

  test "should show tag" do
    get tag_url(@tag.slug), headers: {host: "#{@user.subdomain}.willow.camp"}
    assert_response :success
  end

  test "should find user by subdomain" do
    get tags_url, headers: {host: "#{@user.subdomain}.willow.camp"}
    assert_response :success
  end

  test "should find user by custom domain" do
    get tags_url, headers: {host: @custom_domain_user.custom_domain}
    assert_response :success
  end

  test "should redirect to main site when user not found" do
    get tags_url, headers: {host: "nonexistent.willow.camp"}
    assert_redirected_to root_url(subdomain: false)
  end

  test "should redirect to custom domain when user has one" do
    # Access via subdomain when user has custom domain
    get tags_url, headers: {host: "#{@custom_domain_user.subdomain}.willow.camp"}
    assert_redirected_to "https://#{@custom_domain_user.custom_domain}/tags"
  end

  test "should not redirect when already on custom domain" do
    # Access via custom domain - should not redirect
    get tags_url, headers: {host: @custom_domain_user.custom_domain}
    assert_response :success
  end

  test "should show tag with custom domain" do
    get tag_url(@tag.slug), headers: {host: @custom_domain_user.custom_domain}
    assert_response :success
  end

  test "should redirect tag show to custom domain" do
    get tag_url(@tag.slug), headers: {host: "#{@custom_domain_user.subdomain}.willow.camp"}
    assert_redirected_to "https://#{@custom_domain_user.custom_domain}/t/#{@tag.slug}"
  end

  test "should handle case insensitive domain matching" do
    get tags_url, headers: {host: @custom_domain_user.custom_domain}
    assert_response :success
  end

  test "should handle subdomain with no custom domain normally" do
    get tags_url, headers: {host: "#{@user.subdomain}.willow.camp"}
    assert_response :success
  end
end
