require "test_helper"

class Dashboard::FeaturedPostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @post = create(:post, author: @user, featured: false)
    sign_in @user
  end

  test "should update post to featured" do
    patch dashboard_featured_post_path(@post), params: { featured: "true" }
    
    assert_response :no_content
    assert @post.reload.featured?
  end

  test "should update post to not featured" do
    @post.update!(featured: true)
    
    patch dashboard_featured_post_path(@post), params: { featured: "false" }
    
    assert_response :no_content
    assert_not @post.reload.featured?
  end

  test "should return error when post update fails" do
    # Stub the update method to return false
    Post.any_instance.stubs(:update).returns(false)
    
    patch dashboard_featured_post_path(@post), params: { featured: "true" }, 
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :success
    assert_match "Failed to update featured status", response.body
  end

  test "should not allow updating other user's post" do
    other_user = create(:user)
    other_post = create(:post, author: other_user, featured: false)
    
    assert_raises(ActiveRecord::RecordNotFound) do
      patch dashboard_featured_post_path(other_post), params: { featured: "true" }
    end
  end

  test "should require authentication" do
    sign_out @user
    
    patch dashboard_featured_post_path(@post), params: { featured: "true" }
    
    assert_redirected_to new_user_session_path
  end

  test "should handle turbo stream format on success" do
    patch dashboard_featured_post_path(@post), params: { featured: "true" },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :no_content
    assert @post.reload.featured?
  end

  test "should handle html format redirect on error" do
    Post.any_instance.stubs(:update).returns(false)
    
    patch dashboard_featured_post_path(@post), params: { featured: "true" },
          headers: { "Accept" => "text/html" }
    
    assert_redirected_to dashboard_path
    assert_equal "Failed to update featured status", flash[:alert]
  end
end