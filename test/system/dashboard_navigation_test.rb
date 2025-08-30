require "application_system_test_case"
require "test_helper"

class DashboardNavigationTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @post = posts(:one)
  end

  test "user can log in and see posts" do
    visit new_user_session_path

    fill_in "Email", with: @user.email
    fill_in "Password", with: "password"
    click_button "Log in"

    # Wait for redirect and dashboard to load
    assert_text "Posts"

    # Should see posts list
    assert_text @post.title
  end

  test "user can click new post and see new post form" do
    sign_in_as @user
    assert_text "Posts"

    # Click new post button
    click_button "New Post"

    # Should see the new post form
    assert_selector "form"
    assert_selector "textarea[name='post[body_markdown]']"
    assert_button "Publish"
  end

  test "user can click on existing post and see edit form" do
    sign_in_as @user

    # Wait for dashboard to load
    assert_text "Posts"

    # Click on the post row (table row has onclick handler)
    find("tr", text: @post.title).click

    # Should see the edit form (path uses blog subdomain and ID)
    assert_current_path edit_dashboard_post_path(blog_subdomain: @post.blog.subdomain, id: @post.id)
    assert_selector "form"
    assert_selector "textarea[name='post[body_markdown]']"
    assert_field "post[body_markdown]", with: @post.body_markdown
  end

  test "user can click on tags and see tags list" do
    sign_in_as @user
    assert_text "Posts"

    # Click on tags link
    click_link "Tags"

    # Should see the tags page
    assert_current_path blog_dashboard_tags_path(@user.blogs.first.subdomain)
    assert_text "Tags"
  end

  test "user can click on settings and see settings page" do
    sign_in_as @user
    assert_text "Posts"

    # Click on settings link
    click_link "Settings"

    # Should see the blog settings page
    assert_current_path blog_dashboard_settings_path(@user.blogs.first.subdomain)
    assert_text "Settings"
    assert_text "Blog Settings"
  end

  private

  def sign_in_as(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password"
    click_button "Log in"
  end
end
