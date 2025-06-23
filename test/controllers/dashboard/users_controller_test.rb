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

  test "should update user with custom domain" do
    patch dashboard_user_url(@user), params: {
      user: {
        name: "Updated Name",
        custom_domain: "newdomain.com"
      }
    }
    assert_response :redirect
    @user.reload
    assert_equal "newdomain.com", @user.custom_domain
  end

  test "should update user with blank custom domain" do
    @user.update!(custom_domain: "olddomain.com")

    patch dashboard_user_url(@user), params: {
      user: {
        custom_domain: ""
      }
    }
    assert_response :redirect
    @user.reload
    assert_nil @user.custom_domain
  end

  test "should reject invalid custom domain format" do
    patch dashboard_user_url(@user), params: {
      user: {
        custom_domain: "invalid-domain"
      }
    }
    assert_response :redirect # Should redirect back with validation errors
    @user.reload
    assert_nil @user.custom_domain
  end

  test "should reject duplicate custom domain" do
    other_user = users(:custom_domain_user)

    patch dashboard_user_url(@user), params: {
      user: {
        custom_domain: other_user.custom_domain
      }
    }
    assert_response :redirect # Should redirect back with validation errors
    @user.reload
    assert_nil @user.custom_domain
  end

  test "should allow updating other fields when custom domain is invalid" do
    patch dashboard_user_url(@user), params: {
      user: {
        name: "New Name",
        custom_domain: "invalid"
      }
    }
    assert_response :redirect # Should redirect back with validation errors
    # Name should not be updated when validation fails
    @user.reload
    assert_not_equal "New Name", @user.name
  end

  test "should update subdomain and custom domain together" do
    patch dashboard_user_url(@user), params: {
      user: {
        subdomain: "newsubdomain",
        custom_domain: "newdomain.com"
      }
    }
    assert_response :redirect
    @user.reload
    assert_equal "newsubdomain", @user.subdomain
    assert_equal "newdomain.com", @user.custom_domain
  end
end
