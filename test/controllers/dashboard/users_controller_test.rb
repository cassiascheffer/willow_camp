require "test_helper"

class Dashboard::UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should get user settings page" do
    get dashboard_user_settings_path
    assert_response :success
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:tokens)
    assert_not_nil assigns(:token)
  end

  test "should patch update user profile and respond with turbo stream" do
    patch dashboard_user_url(@user), params: {user: {name: "Updated Name"}}, headers: {"Accept" => "text/vnd.turbo-stream.html"}
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", @response.content_type
  end

  test "should update user name" do
    patch dashboard_user_url(@user), params: {
      user: {
        name: "Updated Name"
      }
    }
    assert_response :redirect
    @user.reload
    assert_equal "Updated Name", @user.name
  end

  test "should update user email" do
    patch dashboard_user_url(@user), params: {
      user: {
        email: "newemail@example.com"
      }
    }
    assert_response :redirect
    @user.reload
    assert_equal "newemail@example.com", @user.email
  end

  test "should update user password" do
    patch dashboard_user_url(@user), params: {
      user: {
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
    }
    assert_response :redirect
    assert @user.reload.valid_password?("newpassword123")
  end

  test "should not update with invalid email" do
    patch dashboard_user_url(@user), params: {
      user: {
        email: "invalid-email"
      }
    }
    assert_response :redirect
    @user.reload
    assert_not_equal "invalid-email", @user.email
  end
end
