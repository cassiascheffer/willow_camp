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
end
