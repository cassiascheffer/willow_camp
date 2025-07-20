require "test_helper"

class PreviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @published_post = posts(:one)
    @unpublished_post = posts(:two)
  end

  test "should redirect to login when not authenticated" do
    get preview_path(@unpublished_post)
    assert_redirected_to new_user_session_path
  end

  test "should show preview for own unpublished post" do
    sign_in @other_user
    get preview_path(@unpublished_post)
    assert_response :success
    assert_select "h1", @unpublished_post.title
  end

  test "should show preview for own published post" do
    sign_in @user
    get preview_path(@published_post)
    assert_response :success
    assert_select "h1", @published_post.title
  end

  test "should redirect when trying to preview another user's post" do
    sign_in @user
    get preview_path(@unpublished_post)
    assert_redirected_to root_path
  end

  test "should use blog layout for preview" do
    sign_in @other_user
    get preview_path(@unpublished_post)
    assert_response :success
    assert_select "header.bg-base-100"
    assert_select "main#main-content"
  end

  test "should set author instance variable for layout" do
    sign_in @other_user
    get preview_path(@unpublished_post)
    assert_response :success
    assert_not_nil assigns(:author)
    assert_equal @other_user, assigns(:author)
  end
end
