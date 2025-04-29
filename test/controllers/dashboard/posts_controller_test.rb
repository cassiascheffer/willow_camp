require "test_helper"

class Dashboard::PostsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get dashboard_posts_new_url
    assert_response :success
  end

  test "should get create" do
    get dashboard_posts_create_url
    assert_response :success
  end

  test "should get edit" do
    get dashboard_posts_edit_url
    assert_response :success
  end

  test "should get update" do
    get dashboard_posts_update_url
    assert_response :success
  end

  test "should get destroy" do
    get dashboard_posts_destroy_url
    assert_response :success
  end
end
