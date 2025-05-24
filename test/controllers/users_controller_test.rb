require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    skip "No routes right now"

    get new_user_url
    assert_response :success
  end
end
