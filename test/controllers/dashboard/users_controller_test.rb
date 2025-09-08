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

  test "should delete user account when no blogs exist" do
    # Ensure user has no blogs
    @user.blogs.destroy_all

    assert_difference("User.count", -1) do
      delete dashboard_user_settings_path
    end

    assert_redirected_to root_path
  end

  test "should not delete user account when blogs exist" do
    # Ensure user has at least one blog
    @user.blogs.create!(subdomain: "testblog", title: "Test Blog", favicon_emoji: "🚀")

    assert_no_difference("User.count") do
      delete dashboard_user_settings_path
    end

    assert_redirected_to dashboard_security_path
    follow_redirect!
    assert_match(/You must delete all your blogs before deleting your account/, response.body)
  end

  test "should delete user account and all associated data" do
    # Clear existing tokens first
    @user.tokens.destroy_all

    # Create some tokens for the user
    token1 = @user.tokens.create!(name: "Test Token 1")
    token2 = @user.tokens.create!(name: "Test Token 2")

    # Ensure user has no blogs
    @user.blogs.destroy_all

    assert_difference("User.count", -1) do
      assert_difference("UserToken.count", -2) do
        delete dashboard_user_settings_path
      end
    end

    assert_redirected_to root_path

    # Verify tokens are deleted
    assert_not UserToken.exists?(token1.id)
    assert_not UserToken.exists?(token2.id)
  end

  test "should require authentication for account deletion" do
    sign_out @user

    assert_no_difference("User.count") do
      delete dashboard_user_settings_path
    end

    assert_redirected_to new_user_session_path
  end

  test "should not delete different user account" do
    other_user = users(:two)

    # Try to delete other user's account (should not be possible through this route)
    assert_no_difference("User.count") do
      delete dashboard_user_settings_path
    end

    # User should still exist
    assert User.exists?(@user.id)
    assert User.exists?(other_user.id)
  end
end
