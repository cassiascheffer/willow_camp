require "test_helper"

class Dashboard::TokensControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    # Use Devise's built-in sign_in helper for faster tests
    sign_in @user
    @token_params = {user_token: {name: "Test API Token", expires_at: 30.days.from_now}}
  end

  test "should create token and redirect to settings" do
    assert_difference("@user.tokens.count") do
      post dashboard_tokens_path, params: @token_params
    end

    assert_redirected_to dashboard_settings_path
    assert_equal "Token created successfully", flash[:notice]
  end

  test "should not create token with invalid attributes" do
    invalid_params = {user_token: {name: "", expires_at: 30.days.from_now}}

    assert_no_difference("@user.tokens.count") do
      post dashboard_tokens_path, params: invalid_params
    end

    assert_redirected_to dashboard_settings_path
    assert_equal "There were errors creating the token", flash[:alert]
  end

  test "should destroy token" do
    token = user_tokens(:active)

    assert_difference("@user.tokens.count", -1) do
      delete dashboard_token_path(token), headers: {"Accept" => "text/vnd.turbo-stream.html"}
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", @response.media_type
    assert_match "Token deleted successfully", @response.body
  end

  test "should destroy token with Turbo Stream request" do
    token = user_tokens(:active)

    assert_difference("@user.tokens.count", -1) do
      delete dashboard_token_path(token), headers: {"Accept" => "text/vnd.turbo-stream.html"}
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", @response.media_type
    assert_match "Token deleted successfully", @response.body
  end

  test "cannot delete another user's token" do
    other_user_token = user_tokens(:future_expiry) # This token belongs to users(:two)

    delete dashboard_token_path(other_user_token)
    assert_response :not_found

    assert_equal 1, UserToken.where(id: other_user_token.id).count
  end

  test "requires authentication" do
    sign_out @user

    post dashboard_tokens_path, params: @token_params
    assert_redirected_to new_user_session_path

    token = user_tokens(:active)
    delete dashboard_token_path(token)
    assert_redirected_to new_user_session_path
  end

  test "should handle token with past expiration date" do
    invalid_params = {user_token: {name: "Test API Token", expires_at: 1.day.ago}}

    assert_no_difference("@user.tokens.count") do
      post dashboard_tokens_path, params: invalid_params
    end

    assert_redirected_to dashboard_settings_path
    assert_equal "There were errors creating the token", flash[:alert]
  end
end
