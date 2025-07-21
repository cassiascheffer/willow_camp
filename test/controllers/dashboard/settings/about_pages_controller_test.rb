require "test_helper"

class Dashboard::Settings::AboutPagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @page = posts(:page_one)
    @page.update!(author: @user)
  end

  test "should create about page with valid params" do
    assert_difference("Page.count") do
      post dashboard_settings_about_pages_url, params: {
        page: {
          title: "About Me",
          body_markdown: "This is my about page",
          published: true,
          slug: "about-me-test"
        }
      }
    end

    assert_redirected_to dashboard_settings_path
    assert_equal "Created!", flash[:notice]

    # Find the page by title since FriendlyId might change the slug
    page = Page.find_by(title: "About Me", author: @user)
    assert_not_nil page, "Page should exist with title 'About Me'"
    assert_equal "About Me", page.title
    assert_equal "This is my about page", page.body_markdown
    assert_equal @user, page.author
  end

  test "should create about page with turbo stream" do
    assert_difference("Page.count") do
      post dashboard_settings_about_pages_url, params: {
        page: {
          title: "About Me",
          body_markdown: "This is my about page",
          published: true,
          slug: "about"
        }
      }, as: :turbo_stream
    end

    assert_response :success
    assert_match "You now have an about page. Nice!", response.body
  end

  test "should not create about page with invalid params" do
    assert_no_difference("Page.count") do
      post dashboard_settings_about_pages_url, params: {
        page: {
          title: "",
          body_markdown: "",
          slug: ""
        }
      }, as: :turbo_stream
    end

    assert_response :success
    assert_match "about-page-form", response.body
  end

  test "should update about page with valid params" do
    patch dashboard_settings_about_page_url(slug: @page.slug), params: {
      page: {
        title: "Updated About",
        body_markdown: "Updated content"
      }
    }

    assert_redirected_to dashboard_settings_path
    assert_equal "Updated!", flash[:notice]

    @page.reload
    assert_equal "Updated About", @page.title
    assert_equal "Updated content", @page.body_markdown
  end

  test "should update about page with turbo stream" do
    patch dashboard_settings_about_page_url(slug: @page.slug), params: {
      page: {
        title: "Updated About",
        body_markdown: "Updated content"
      }
    }, as: :turbo_stream

    assert_response :success
    assert_match "Updated!", response.body
  end

  test "should not update about page with invalid params" do
    patch dashboard_settings_about_page_url(slug: @page.slug), params: {
      page: {
        title: "",
        slug: ""
      }
    }, as: :turbo_stream

    assert_response :success
    assert_match "about-page-form", response.body
    @page.reload
    assert_not_equal "", @page.title
  end

  test "should destroy about page" do
    assert_difference("Page.count", -1) do
      delete dashboard_settings_about_page_url(slug: @page.slug)
    end

    assert_redirected_to dashboard_settings_path
    assert_equal "Page was successfully deleted.", flash[:notice]
  end

  test "should destroy about page with turbo stream and recreate default" do
    assert_difference("Page.count", 0) do
      delete dashboard_settings_about_page_url(slug: @page.slug), as: :turbo_stream
    end

    assert_response :success
    assert_match "Page was successfully deleted.", response.body

    # Check that a new about page was created
    new_about = @user.pages.find_by(slug: "about")
    assert_not_nil new_about
    assert_equal "About", new_about.title
  end

  test "should not find page for different user" do
    # Ensure page belongs to first user
    assert_equal @user.id, @page.author_id

    # Create a second user and sign them in
    other_user = users(:two)
    sign_out @user
    sign_in other_user

    # The controller should not find the page since it belongs to a different user
    # Rails handles RecordNotFound and returns a 404
    patch dashboard_settings_about_page_url(slug: @page.slug), params: {
      page: {title: "Hacked!"}
    }

    assert_response :not_found
  end

  test "should require authentication" do
    sign_out @user

    post dashboard_settings_about_pages_url, params: {
      page: {title: "Test"}
    }

    assert_redirected_to new_user_session_path
  end
end
