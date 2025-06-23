require "test_helper"

class Dashboard::PostsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @post = posts(:one)
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
end
