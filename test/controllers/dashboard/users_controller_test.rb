require "test_helper"

class Dashboard::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @headers = { "Accept" => "text/vnd.turbo-stream.html" }
  end

  test "should patch update and respond with turbo stream" do
    patch dashboard_user_url(@user), params: { user: { name: "Updated Name" } }, headers: @headers
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", @response.content_type
  end
end
