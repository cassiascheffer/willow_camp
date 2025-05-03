require "test_helper"

class Dasboard::UsersControllerTest < ActionDispatch::IntegrationTest
  test "should get edit" do
    get dasboard_users_edit_url
    assert_response :success
  end

  test "should get update" do
    get dasboard_users_update_url
    assert_response :success
  end
end
