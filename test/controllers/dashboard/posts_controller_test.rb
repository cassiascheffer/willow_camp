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

  test "should set existing_tags in edit action" do
    get edit_dashboard_post_url(@post.id)
    assert_response :success
    assert_not_nil assigns(:existing_tags)
    assert_kind_of Array, assigns(:existing_tags)
  end

  test "existing_tags should include user's tags in edit action" do
    # Create a post with tags for the user
    tagged_post = @user.posts.create!(title: "Tagged Post", body_markdown: "Content")
    tagged_post.tag_list = "ruby, rails, testing"
    tagged_post.save!

    get edit_dashboard_post_url(@post.id)
    assert_response :success

    existing_tags = assigns(:existing_tags)
    assert_includes existing_tags, "ruby"
    assert_includes existing_tags, "rails"
    assert_includes existing_tags, "testing"
  end

  test "existing_tags should be empty array when user has no tags" do
    # Create a new post for the existing user (who has no tags yet)
    untagged_post = @user.posts.create!(
      title: "Untagged Post",
      body_markdown: "Content"
    )

    get edit_dashboard_post_url(untagged_post.id)
    assert_response :success
    assert_equal [], assigns(:existing_tags)
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
