require "test_helper"

class Dashboard::PostsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActionDispatch::TestProcess::FixtureFile

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

  # Social Share Image Tests
  test "should permit social_share_image parameter" do
    image_file = fixture_file_upload("test_image.png", "image/png")

    patch dashboard_post_url(@post.id), params: {
      post: {
        title: "Updated Title",
        social_share_image: image_file
      }
    }

    # Should not raise parameter not permitted error
    assert_response :redirect
  end

  test "should allow manual image attachment via Active Storage" do
    image_file = fixture_file_upload("test_image.png", "image/png")

    assert_not @post.social_share_image.attached?

    # Simulate what the JavaScript does - directly attach via Active Storage
    @post.social_share_image.attach(image_file)

    assert @post.social_share_image.attached?
  end
end
