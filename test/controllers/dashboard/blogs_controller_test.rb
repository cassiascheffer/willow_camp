# ABOUTME: Test file for dashboard blogs controller functionality
# ABOUTME: Tests blog creation and management for authenticated users
require "test_helper"

class Dashboard::BlogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:test_user_no_blog)
    sign_in @user
  end

  test "should create blog with valid subdomain" do
    assert_difference("Blog.count", 1) do
      post dashboard_blogs_path, params: {blog: {subdomain: "testblog", primary: true}}
    end

    assert_redirected_to blog_dashboard_path("testblog")
    assert_equal "Blog created successfully!", flash[:notice]

    blog = @user.blogs.find_by(subdomain: "testblog")
    assert_not_nil blog, "Blog with subdomain 'testblog' should have been created for user"
    assert_equal "testblog", blog.subdomain
    assert_equal @user, blog.user
    assert blog.primary, "Blog should be marked as primary"
  end

  test "should not create blog with invalid subdomain" do
    assert_no_difference("Blog.count") do
      post dashboard_blogs_path, params: {blog: {subdomain: "ab"}}
    end

    assert_redirected_to dashboard_path
    assert_match(/Subdomain is too short/, flash[:alert])
  end

  test "should not create blog with duplicate subdomain" do
    Blog.create!(user: @user, subdomain: "existingblog")

    assert_no_difference("Blog.count") do
      post dashboard_blogs_path, params: {blog: {subdomain: "existingblog"}}
    end

    assert_redirected_to dashboard_path
    assert_match(/Subdomain has already been taken/, flash[:alert])
  end

  test "should require authentication" do
    sign_out @user

    post dashboard_blogs_path, params: {blog: {subdomain: "testblog"}}

    assert_redirected_to new_user_session_path
  end
end
