require "application_system_test_case"

class PostsTest < ApplicationSystemTestCase
  setup do
    @post = posts(:one)
    @user = users(:one)

    # Sign in as the user
    visit new_session_path
    fill_in "Enter your email address", with: @user.email_address
    fill_in "Enter your password", with: "password" # Assuming this is the password in fixtures
    click_on "Sign in"
  end

  test "visiting the index" do
    visit posts_url
    assert_selector "h1", text: "Blog Posts"
  end

  test "should create post" do
    visit dashboard_posts_path
    click_on "New Post"

    fill_in "Title", with: "#{@post.title} #{Time.current.to_i}"
    fill_in "Body", with: @post.body
    check "Published" if @post.published
    click_on "Create Post"

    assert_text "Post was successfully created"
  end

  test "should update Post" do
    visit dashboard_posts_path
    click_on "Edit", match: :first

    fill_in "Title", with: "Updated #{@post.title}"
    fill_in "Body", with: @post.body
    check "Published" if @post.published
    click_on "Update Post"

    assert_text "Post was successfully updated"
  end

  test "should destroy Post" do
    visit dashboard_posts_path

    accept_confirm do
      click_on "Delete", match: :first
    end

    assert_text "Post was successfully destroyed"
  end
end
