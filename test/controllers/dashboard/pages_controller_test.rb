require "test_helper"

class Dashboard::PagesControllerTest < ActionDispatch::IntegrationTest
  fixtures :posts

  setup do
    @user = users(:one)
    @page = posts(:page_one)
    # Login the user
    post session_url, params: {email_address: @user.email_address, password: "password"}
  end

  test "should get new" do
    get new_dashboard_page_url
    assert_response :success
  end

  test "should post create" do
    assert_difference("Page.count") do
      post dashboard_pages_url, params: {page: {title: "New Test Page"}}
    end
    created_page = Page.order(:created_at).last
    assert_redirected_to dashboard_page_url(slug: created_page.slug)
  end

  test "should get edit" do
    get edit_dashboard_page_url(slug: @page.slug)
    assert_response :success
  end

  test "should patch update" do
    patch dashboard_page_url(slug: @page.slug), params: {page: {title: "Updated Title"}}
    @page.reload
    assert_redirected_to dashboard_page_url(slug: @page.slug)
  end

  test "should delete destroy" do
    assert_difference("Page.count", -1) do
      delete dashboard_page_url(slug: @page.slug)
    end
    assert_redirected_to dashboard_pages_url
  end
end
