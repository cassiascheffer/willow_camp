require "test_helper"

class Dashboard::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    # Login the user
    post session_url, params: { email_address: @user.email_address, password: "password" }
    @headers = { "Accept" => "text/html" }
  end

  test "should get edit" do
    get edit_dashboard_user_url(@user), headers: @headers
    assert_response :success
  end

  test "should patch update" do
    patch dashboard_user_url(@user), params: { user: { name: "Updated Name" } }, headers: @headers
    assert_redirected_to dashboard_url
  end
end
