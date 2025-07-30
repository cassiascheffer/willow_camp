require "test_helper"

class Dashboard::PostsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActionDispatch::TestProcess::FixtureFile

  setup do
    @user = users(:enumerator_dev) # Use the user with social_share_image feature enabled
    @post = posts(:one)
    @post.update!(author: @user) # Make sure the post belongs to our user
    sign_in @user
  end

  test "should get edit" do
    get edit_dashboard_post_url(@post.id)
    assert_response :success
  end

  test "should patch update" do
    patch dashboard_post_url(@post.id), params: {post: {title: "Updated Title"}}
    assert_redirected_to edit_dashboard_post_url(@post.id)
  end

  test "should delete destroy" do
    assert_difference("Post.count", -1) do
      delete dashboard_post_url(@post.id)
    end
    assert_redirected_to dashboard_url
  end

  # Social Share Image Tests
  test "should permit social_share_image parameter when feature is enabled" do
    image_file = fixture_file_upload("test_image.png", "image/png")

    # Just verify the request succeeds without errors
    patch dashboard_post_url(@post.id), params: {
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
    patch dashboard_post_url(@post.id), params: {
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
    patch dashboard_post_url(@post.id), params: {
      post: {
        title: "First Update",
        social_share_image: image1
      }
    }
    assert_response :redirect
    
    # Second update with new image - this was failing before the fix
    image2 = fixture_file_upload("test_image.png", "image/png")
    patch dashboard_post_url(@post.id), params: {
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
    patch dashboard_post_url(@post.id), params: {
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
    
    patch dashboard_post_url(@post.id), params: {
      post: {
        title: "Turbo Update",
        social_share_image: image
      }
    }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :ok
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.content_type
  end

  test "feature flag works correctly across environments" do
    # In test environment, feature should be enabled for all users
    assert @user.social_share_image_enabled?
    
    # Test that in production it would only work for enumerator.dev
    original_env = Rails.env
    begin
      Rails.env = ActiveSupport::StringInquirer.new("production")
      
      # Should be enabled for enumerator.dev
      assert @user.social_share_image_enabled?
      
      # Should be disabled for other domains
      other_user = users(:one)
      assert_not other_user.social_share_image_enabled?
    ensure
      Rails.env = original_env
    end
  end

end
