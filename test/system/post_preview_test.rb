require "application_system_test_case"

class PostPreviewTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @unpublished_post = posts(:two)
    @published_post = posts(:one)
  end

  test "preview button appears for unpublished posts" do
    sign_in_as users(:two)
    visit edit_dashboard_post_path(@unpublished_post)

    assert_text "Preview post"
    assert_no_text "View post"
  end

  test "view post button appears for published posts" do
    sign_in_as users(:one)
    visit edit_dashboard_post_path(@published_post)

    assert_text "View post"
    assert_no_text "Preview post"
  end

  test "clicking preview button opens preview in new tab" do
    sign_in_as users(:two)
    visit edit_dashboard_post_path(@unpublished_post)

    preview_link = find_link("Preview post")
    assert_equal "_blank", preview_link[:target]
    assert_equal preview_path(@unpublished_post), preview_link[:href]
  end

  test "preview page shows post content with blog layout" do
    sign_in_as users(:two)
    visit preview_path(@unpublished_post)

    assert_text @unpublished_post.title
    assert_text @unpublished_post.body_markdown
    assert_selector "header.bg-base-100"
    assert_selector "main#main-content"
  end

  private

  def sign_in_as(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password"
    click_button "Log in"
  end
end
