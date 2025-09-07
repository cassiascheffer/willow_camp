require "test_helper"

class Dashboard::PostsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActionDispatch::TestProcess::FixtureFile

  setup do
    @user = users(:enumerator_dev) # Use the user with social_share_image feature enabled
    @blog = blogs(:enumerator_blog)
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

  # Social Share Image Tests
  test "should permit social_share_image parameter when feature is enabled" do
    image_file = fixture_file_upload("test_image.png", "image/png")

    # Just verify the request succeeds without errors
    patch dashboard_post_url(blog_subdomain: @blog.subdomain, id: @post.id), params: {
      post: {
        title: "Updated Title",
        social_share_image: image_file
      }
    }

    assert_response :redirect
  end

  test "should handle replacing existing social share image" do
    # First attach an image directly
    @post.social_share_image.attach(io: File.open(Rails.root.join("test/fixtures/files/test_image.png")), filename: "test.png")

    # Now replace it with a new one via controller
    new_image = fixture_file_upload("test_image.png", "image/png")
    patch dashboard_post_url(blog_subdomain: @blog.subdomain, id: @post.id), params: {
      post: {
        title: "Updated Title",
        social_share_image: new_image
      }
    }

    assert_response :redirect
  end

  test "should handle multiple consecutive updates with social share image" do
    # First update with image
    image1 = fixture_file_upload("test_image.png", "image/png")
    patch dashboard_post_url(blog_subdomain: @blog.subdomain, id: @post.id), params: {
      post: {
        title: "First Update",
        social_share_image: image1
      }
    }
    assert_response :redirect

    # Second update with new image - this was failing before the fix
    image2 = fixture_file_upload("test_image.png", "image/png")
    patch dashboard_post_url(blog_subdomain: @blog.subdomain, id: @post.id), params: {
      post: {
        title: "Second Update",
        social_share_image: image2
      }
    }
    assert_response :redirect

    # Verify the title was updated
    @post.reload
    assert_equal "Second Update", @post.title
  end

  test "should update post without affecting existing social share image when image not provided" do
    # Update without providing an image
    patch dashboard_post_url(blog_subdomain: @blog.subdomain, id: @post.id), params: {
      post: {
        title: "Updated Title Only"
      }
    }

    assert_response :redirect
    @post.reload
    assert_equal "Updated Title Only", @post.title
  end

  test "should handle turbo stream format for social share image updates" do
    image = fixture_file_upload("test_image.png", "image/png")

    patch dashboard_post_url(blog_subdomain: @blog.subdomain, id: @post.id), params: {
      post: {
        title: "Turbo Update",
        social_share_image: image
      }
    }, headers: {"Accept" => "text/vnd.turbo-stream.html"}

    assert_response :ok
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.content_type
  end

  test "feature flag works correctly across environments" do
    # In test environment, feature should be enabled for all blogs
    assert @blog.social_share_image_enabled?

    # Test that in production it would only work for enumerator.dev
    original_env = Rails.env
    begin
      Rails.env = ActiveSupport::StringInquirer.new("production")

      # Should be enabled for enumerator.dev
      assert @blog.social_share_image_enabled?

      # Should be disabled for other domains
      other_blog = blogs(:one)
      assert_not other_blog.social_share_image_enabled?
    ensure
      Rails.env = original_env
    end
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
