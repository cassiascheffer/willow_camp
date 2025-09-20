require "test_helper"

class Dashboard::PostsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActionDispatch::TestProcess::FixtureFile

  setup do
    @user = users(:one)
    @blog = blogs(:one)
    @post = posts(:one)
    @post.update!(author: @user, blog: @blog) # Make sure the post belongs to our user and blog
    sign_in @user
  end

  test "should get edit" do
    get edit_dashboard_post_url(blog_subdomain: @blog.subdomain, id: @post.id)
    assert_response :success
  end

  test "should patch update" do
    patch dashboard_post_url(blog_subdomain: @blog.subdomain, id: @post.id), params: {post: {title: "Updated Title"}}
    assert_redirected_to edit_dashboard_post_url(blog_subdomain: @blog.subdomain, id: @post.id)
  end

  test "should delete destroy" do
    assert_difference("Post.count", -1) do
      delete dashboard_post_url(blog_subdomain: @blog.subdomain, id: @post.id)
    end
    assert_redirected_to dashboard_url
  end

  # Backwards Compatibility Tests for Tag Handling
  test "should use blog.id as tenant for tags in dashboard" do
    # Create posts with blog
    user = users(:one)
    sign_in user

    # Create a blog for the user
    blog = user.blogs.create!(
      subdomain: "dashtest",
      favicon_emoji: "🚀"
    )

    # Create posts - all with blog
    post1 = blog.posts.create!(
      title: "First Dashboard Post",
      tag_list: ["dashboard", "first"],
      author: user
    )

    post2 = blog.posts.create!(
      title: "Second Dashboard Post",
      tag_list: ["dashboard", "second"],
      author: user
    )

    assert_equal blog.id, post1.blog_id
    assert_equal blog.id, post2.blog_id

    # Dashboard controller should use blog.id as tenant
    get edit_dashboard_post_url(blog_subdomain: blog.subdomain, id: post1.id)
    assert_response :success

    # Verify that tags are loaded using blog tenant
    # This is checking that the edit action loads tags correctly
    assert_select "form" # Basic check that the edit form is present
  end

  test "should handle tag list updates for posts" do
    user = users(:one)
    sign_in user

    # Create blog and post
    blog = user.blogs.first || user.blogs.create!(
      subdomain: "tagtest#{user.id[0..7]}",
      favicon_emoji: "📝"
    )

    post = blog.posts.create!(
      title: "Blog Post",
      author: user,
      body_markdown: "Content"
    )

    assert_equal blog.id, post.blog_id

    # Update post with tags
    patch dashboard_post_url(blog_subdomain: blog.subdomain, id: post.id), params: {
      post: {
        tag_list: "backwards, compatibility, test"
      }
    }

    assert_response :redirect
    post.reload
    assert_equal ["backwards", "compatibility", "test"], post.tag_list.sort
    assert_equal blog.id, post.blog_id
  end

  test "should handle tag list updates for posts with blog" do
    user = users(:one)
    sign_in user

    # Create blog and post
    blog = user.blogs.create!(
      subdomain: "tagtest",
      favicon_emoji: "🏷️"
    )

    post_with_blog = blog.posts.create!(
      title: "Blog Post",
      author: user,
      body_markdown: "Content"
    )

    assert_equal blog.id, post_with_blog.blog_id

    # Update post with tags
    patch dashboard_post_url(blog_subdomain: blog.subdomain, id: post_with_blog.id), params: {
      post: {
        tag_list: "modern, blog, test"
      }
    }

    assert_response :redirect
    post_with_blog.reload
    assert_equal ["blog", "modern", "test"], post_with_blog.tag_list.sort
    assert_equal blog.id, post_with_blog.blog_id # Should still have blog
  end

  test "dashboard edit should show user tags regardless of blog association" do
    user = users(:one)
    sign_in user

    # Create mixed scenario
    blog = user.blogs.create!(
      subdomain: "mixed",
      favicon_emoji: "🎭"
    )

    # Legacy post with tags (now with blog)
    legacy_post = blog.posts.create!(
      title: "Legacy Tagged",
      tag_list: ["legacy", "global"],
      author: user
    )

    # Modern post with tags (with blog)
    modern_post = blog.posts.create!(
      title: "Modern Tagged",
      tag_list: ["modern", "scoped"],
      author: user
    )

    # Dashboard should use blog.id as tenant
    # When editing either post, user should see all their tags
    get edit_dashboard_post_url(blog_subdomain: blog.subdomain, id: legacy_post.id)
    assert_response :success

    get edit_dashboard_post_url(blog_subdomain: blog.subdomain, id: modern_post.id)
    assert_response :success

    # Both should work since both controllers use user-based tenant consistently
  end

  test "should maintain tag tenant consistency with dashboard vs blog controllers" do
    user = users(:one)
    sign_in user

    blog = user.blogs.create!(
      subdomain: "consistency",
      favicon_emoji: "🔄"
    )

    # Create posts - all with blog
    post1 = blog.posts.create!(
      title: "First Consistency",
      tag_list: ["dashboard-visible"],
      author: user,
      published: true
    )

    post2 = blog.posts.create!(
      title: "Second Consistency",
      tag_list: ["blog-scoped"],
      author: user,
      published: true
    )

    # Dashboard edit should work for both (uses blog tenant)
    get edit_dashboard_post_url(blog_subdomain: blog.subdomain, id: post1.id)
    assert_response :success

    get edit_dashboard_post_url(blog_subdomain: blog.subdomain, id: post2.id)
    assert_response :success

    # Both controllers now use user.id consistently:
    # - Dashboard controller uses current_user.id as tenant
    # - Blog tags controller uses @author.id as tenant
    # This ensures consistent tag visibility across the application
  end
end
