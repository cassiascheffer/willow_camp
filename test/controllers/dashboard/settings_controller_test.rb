require "test_helper"

class Dashboard::SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @blog = blogs(:one)
    @token1 = user_tokens(:active)
    @token2 = user_tokens(:expired)
  end

  test "should redirect to session/new when not logged in" do
    get blog_dashboard_settings_path(blog_subdomain: @blog.subdomain)
    assert_redirected_to new_user_session_path
  end

  test "should get show when logged in" do
    sign_in(@user)
    get blog_dashboard_settings_path(blog_subdomain: @blog.subdomain)
    assert_response :success
    assert_not_nil controller.instance_variable_get(:@blog)
    assert_not_nil controller.instance_variable_get(:@about_page)
    assert_equal @blog, controller.instance_variable_get(:@blog)
    assert_nil controller.instance_variable_get(:@tokens)
    assert_nil controller.instance_variable_get(:@token)
  end
end
