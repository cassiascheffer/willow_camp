require "test_helper"

class Dashboard::PostsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @post = posts(:one)
    sign_in @user
  end

  test "should get new" do
    get new_dashboard_post_url
    assert_response :success
  end

  test "should post create" do
    assert_difference("Post.count") do
      post dashboard_posts_url, params: {post: {title: "New Test Post"}}
    end
    assert_redirected_to dashboard_url
  end

  test "should get edit" do
    get edit_dashboard_post_url(slug: @post.slug)
    assert_response :success
  end

  test "should patch update" do
    patch dashboard_post_url(slug: @post.slug), params: {post: {title: "Updated Title"}}
    assert_redirected_to dashboard_url
  end

  test "should delete destroy" do
    assert_difference("Post.count", -1) do
      delete dashboard_post_url(slug: @post.slug)
    end
    assert_redirected_to dashboard_url
  end
end
