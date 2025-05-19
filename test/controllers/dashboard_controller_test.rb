require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    # Login the user
    post session_url, params: { email_address: @user.email_address, password: "password" }
  end

  test "should get show" do
    get dashboard_url
    assert_response :success
  end
end
