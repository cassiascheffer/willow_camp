require "test_helper"

class Dashboard::UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should patch update and respond with turbo stream" do
    patch dashboard_user_url(@user), params: {user: {name: "Updated Name"}}, headers: {"Accept" => "text/vnd.turbo-stream.html"}
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", @response.content_type
  end
end
