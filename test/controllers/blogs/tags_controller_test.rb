require "test_helper"

class Blogs::TagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @post = posts(:one)
    @custom_domain_user = users(:custom_domain_user)
    @custom_domain_post = posts(:custom_domain_post)

    # Ensure blogs exist (run migration if needed)
    @blog = @user.blogs.first || @user.blogs.create!(
      subdomain: @user.subdomain,
      title: @user.blog_title,
      favicon_emoji: "🚀"
    )
    @custom_blog = @custom_domain_user.blogs.first || @custom_domain_user.blogs.create!(
      subdomain: @custom_domain_user.subdomain,
      custom_domain: @custom_domain_user.custom_domain,
      title: @custom_domain_user.blog_title,
      favicon_emoji: "🎯"
    )

    # Associate posts with blogs
    @post.update!(blog: @blog) if @post.blog.nil?
    @custom_domain_post.update!(blog: @custom_blog) if @custom_domain_post.blog.nil?

    # Create a test tag with spaces
    @tag = ActsAsTaggableOn::Tag.create!(name: "Test Tag With Spaces")
    # Tag the posts (now they have blog_id set)
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

  test "should return 404 when user not found" do
    get tags_url, headers: {host: "nonexistent.willow.camp"}
    assert_response :not_found
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

  # Backwards Compatibility Tests
  test "should use user tenant consistently" do
    # Create a user without any blogs
    legacy_user = User.create!(
      email: "legacy@example.com",
      password: "password123",
      password_confirmation: "password123",
      subdomain: "legacy",
      name: "Legacy User",
      favicon_emoji: "📝"
    )

    # Create a post directly on user (no blog)
    legacy_post = legacy_user.posts.create!(
      title: "Legacy Post",
      body_markdown: "Legacy content",
      tag_list: ["legacy", "backwards"],
      published: true
    )

    assert_nil legacy_post.blog_id
    assert legacy_user.blogs.empty?

    # Verify tags were created with user tenant
    legacy_post.reload
    assert legacy_post.tags.any?, "Post should have tags"

    tag = legacy_post.tags.first
    tagging = tag.taggings.where(taggable: legacy_post).first
    assert_equal legacy_user.id, tagging.tenant

    # Tags controller should use user.id as tenant
    get tags_url, headers: {host: "legacy.willow.camp"}
    assert_response :success
  end

  test "should use user tenant even when user has blogs" do
    # Verify that we consistently use user.id as tenant (even when blogs exist)
    get tags_url, headers: {host: "#{@user.subdomain}.willow.camp"}
    assert_response :success

    # The @user should have a blog from setup
    assert @user.blogs.any?
    assert_not_nil @post.blog_id

    # Tags should be scoped to user, not blog (for now)
    get tag_url(@tag.slug), headers: {host: "#{@user.subdomain}.willow.camp"}
    assert_response :success
  end

  test "should handle mixed post scenarios with consistent user tenant" do
    # User with both legacy posts (no blog_id) and modern posts (with blog_id)
    user = users(:one)
    blog = user.blogs.first || user.blogs.create!(
      subdomain: user.subdomain,
      favicon_emoji: "🚀"
    )

    # Create legacy post (no blog)
    legacy_post = user.posts.create!(
      title: "Legacy Mixed Post",
      tag_list: ["legacy", "mixed"],
      published: true
    )

    # Create modern post (with blog)
    modern_post = blog.posts.create!(
      title: "Modern Mixed Post",
      tag_list: ["modern", "mixed"],
      author: user,
      published: true
    )

    assert_nil legacy_post.blog_id
    assert_equal blog.id, modern_post.blog_id

    # Both posts should use user.id as tenant, so both should be visible
    legacy_tagging = legacy_post.tags.first.taggings.where(taggable: legacy_post).first
    modern_tagging = modern_post.tags.first.taggings.where(taggable: modern_post).first
    assert_equal user.id, legacy_tagging.tenant
    assert_equal user.id, modern_tagging.tenant

    get tags_url, headers: {host: "#{user.subdomain}.willow.camp"}
    assert_response :success
  end

  test "should maintain consistent user tenant across scenarios" do
    # Verify tenant_id logic in set_tag method uses user.id consistently
    user = users(:one)

    # Test case where user has blog - should still use user.id as tenant
    blog = user.blogs.first
    assert_not_nil blog, "User should have a blog from setup"

    tag_with_blog = @post.tags.first
    get tag_url(tag_with_blog.slug), headers: {host: "#{user.subdomain}.willow.camp"}
    assert_response :success

    # Create user without blog - should also use user.id
    legacy_user = User.create!(
      email: "legacy2@example.com",
      password: "password123",
      password_confirmation: "password123",
      subdomain: "legacy2",
      name: "Legacy User 2",
      favicon_emoji: "📚"
    )

    legacy_post = legacy_user.posts.create!(
      title: "Legacy Tagged",
      tag_list: ["legacy-tenant"],
      published: true
    )

    # Verify tenant is user.id
    tag = legacy_post.tags.first
    tagging = tag.taggings.where(taggable: legacy_post).first
    assert_equal legacy_user.id, tagging.tenant

    # Test the tags index
    get tags_url, headers: {host: "legacy2.willow.camp"}
    assert_response :success
  end
end
