require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
  end

  test "should sign out current user and show registration form when already signed in" do
    sign_in @user

    get new_user_registration_url
    assert_response :success

    # Verify the registration form is displayed
    assert_select "form[action=?]", user_registration_path

    # Verify user is signed out after accessing registration page
    get dashboard_url
    assert_redirected_to new_user_session_url
  end

  test "should show registration form when not signed in" do
    get new_user_registration_url
    assert_response :success
    assert_select "form[action=?]", user_registration_path
  end

  test "after_sign_up_path_for should redirect to dashboard" do
    controller = Users::RegistrationsController.new
    controller.request = ActionDispatch::TestRequest.create
    user = User.new

    assert_equal dashboard_path, controller.after_sign_up_path_for(user)
  end

  test "should return ambiguous error when email is already taken" do
    existing_user = users(:one)

    post user_registration_url, params: {
      user: {
        email: existing_user.email,
        password: "validpassword123",
        password_confirmation: "validpassword123"
      }
    }

    assert_response :unprocessable_entity
    assert_select ".alert-error",
      text: /Oops! That information didn't work. Please check your email and password and try again./
    # Should NOT reveal specific validation errors like "already been taken"
    assert_select ".alert-error", text: /already been taken/i, count: 0
    assert_select ".alert-error", text: /has been taken/i, count: 0
  end

  test "should return ambiguous error when password is too short" do
    post user_registration_url, params: {
      user: {
        email: "newuser@example.com",
        password: "short",
        password_confirmation: "short"
      }
    }

    assert_response :unprocessable_entity
    assert_select ".alert-error",
      text: /Oops! That information didn't work. Please check your email and password and try again./
    # Should NOT reveal specific password requirements like "too short" or "minimum"
    assert_select ".alert-error", text: /too short/i, count: 0
    assert_select ".alert-error", text: /minimum/i, count: 0
  end

  test "should return same error message for email taken and password issues" do
    existing_user = users(:one)

    # Test with taken email
    post user_registration_url, params: {
      user: {
        email: existing_user.email,
        password: "validpassword123",
        password_confirmation: "validpassword123"
      }
    }
    assert_response :unprocessable_entity
    assert_select ".alert-error",
      text: /Oops! That information didn.t work. Please check your email and password and try again./

    # Test with short password
    post user_registration_url, params: {
      user: {
        email: "newuser@example.com",
        password: "short",
        password_confirmation: "short"
      }
    }
    assert_response :unprocessable_entity
    assert_select ".alert-error",
      text: /Oops! That information didn.t work. Please check your email and password and try again./
  end
end
