require "test_helper"

class Dashboard::SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @token1 = user_tokens(:active)
    @token2 = user_tokens(:expired)
  end

  test "should redirect to session/new when not logged in" do
    get dashboard_settings_path
    assert_redirected_to new_session_path
  end

  test "should get show when logged in" do
    sign_in(@user)
    get dashboard_settings_path
    assert_response :success
    assert_not_nil controller.instance_variable_get(:@tokens)
    assert_not_nil controller.instance_variable_get(:@token)
    assert_instance_of UserToken, controller.instance_variable_get(:@token)
    assert_includes controller.instance_variable_get(:@tokens), @token1
    assert_includes controller.instance_variable_get(:@tokens), @token2
  end
end
