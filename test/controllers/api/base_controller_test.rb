require "test_helper"

class Api::BaseControllerTest < ActionDispatch::IntegrationTest
  class TestController < Api::BaseController
    def index
      render json: { success: true, user_id: @current_user.id }
    end
  end

  setup do
    @user = users(:one)
    # Create a test token for the user
    @token = UserToken.create(user: @user, name: "Test Token").token
    @headers = { "Authorization" => "Bearer #{@token}" }

    # Set up a test route that uses our test controller
    Rails.application.routes.draw do
      namespace :api do
        get "test", to: "base_controller_test/test#index"
      end
    end
  end

  teardown do
    # Reset routes to their original state
    Rails.application.reload_routes!
  end

  test "should allow access with valid token" do
    get api_test_url, headers: @headers, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal true, json_response["success"]
    assert_equal @user.id, json_response["user_id"]
  end

  test "should reject access with invalid token" do
    get api_test_url, headers: { "Authorization" => "Bearer invalid_token" }, as: :json
    assert_response :unauthorized

    json_response = JSON.parse(response.body)
    assert_equal "Unauthorized", json_response["error"]
  end

  test "should reject access with missing token" do
    get api_test_url, as: :json
    assert_response :unauthorized

    json_response = JSON.parse(response.body)
    assert_equal "Unauthorized", json_response["error"]
  end

  test "should reject access with malformed authorization header" do
    get api_test_url, headers: { "Authorization" => "malformed_header" }, as: :json
    assert_response :unauthorized

    json_response = JSON.parse(response.body)
    assert_equal "Unauthorized", json_response["error"]
  end

  test "should reject access with expired token" do
    expired_token = UserToken.create(
      user: @user,
      name: "Expired Token",
      expires_at: 1.day.ago
    ).token

    get api_test_url, headers: { "Authorization" => "Bearer #{expired_token}" }, as: :json
    assert_response :unauthorized

    json_response = JSON.parse(response.body)
    assert_equal "Unauthorized", json_response["error"]
  end
end
