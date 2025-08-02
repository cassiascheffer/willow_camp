require "test_helper"

class SocialShareImageWorkflowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActionDispatch::TestProcess::FixtureFile

  setup do
    @user = users(:enumerator_dev)
    @post = posts(:enumerator_post)
    sign_in @user
  end

  test "should have social_share_image attachment capability" do
    # Verify post has the attachment association
    assert_respond_to @post, :social_share_image
    assert_respond_to @post.social_share_image, :attach
    assert_respond_to @post.social_share_image, :attached?
  end

  test "should clean up post successfully regardless of attachments" do
    post_id = @post.id

    # Delete the post
    @post.destroy!

    # Verify post is gone
    assert_not Post.exists?(post_id)
  end

  test "should be able to edit post form without image attachment failing" do
    get edit_dashboard_post_path(@post)
    assert_response :success

    # Verify the form contains social share image elements
    assert_select 'canvas[data-social-share-image-target="canvas"]', 1
    assert_select 'input[name="post[social_share_image]"]', 1
  end

  test "should display canvas preview in edit form" do
    get edit_dashboard_post_path(@post)
    assert_response :success

    # Should show canvas for preview
    assert_select 'canvas[data-social-share-image-target="canvas"]', 1
    assert_select "div", text: /Social Share Image Preview/
  end

  test "should allow updating post attributes" do
    # Update other attributes
    patch dashboard_post_path(@post), params: {
      post: {title: "Updated Title", body_markdown: "Updated content"}
    }

    assert_response :redirect # Just verify it redirects successfully

    @post.reload
    assert_equal "Updated Title", @post.title
    assert_equal "Updated content", @post.body_markdown
  end
end
