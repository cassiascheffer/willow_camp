require "test_helper"

class Dashboard::UntitledPostsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should create untitled post and redirect to edit" do
    assert_difference("Post.count") do
      post dashboard_untitled_posts_url
    end

    created_post = @user.posts.order(:created_at).last
    assert_equal "Untitled", created_post.title
    assert_equal "untitled", created_post.slug
    assert_equal false, created_post.published

    assert_redirected_to edit_dashboard_post_path(created_post.id)
  end

  test "should require authentication" do
    sign_out @user
    post dashboard_untitled_posts_url
    assert_redirected_to new_user_session_path
  end
end
