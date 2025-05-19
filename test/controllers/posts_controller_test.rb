require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
    @user = users(:one)
    host = "#{@user.subdomain}.example.com"
    @headers = { host: host }
  end

  test "should get index" do
    get posts_url, headers: @headers
    assert_response :success
  end

  test "should show post" do
    get "/#{@post.slug}", headers: @headers
    assert_response :success
  end

  # All the remaining tests should be redirected to the dashboard namespace since
  # the main PostsController only handles index and show actions
  test "should get new when signed in" do
    post session_url, params: { email_address: @user.email_address, password: "password" }
    get new_dashboard_post_url
    assert_response :success
  end

  test "should create post when signed in" do
    post session_url, params: { email_address: @user.email_address, password: "password" }
    assert_difference("Post.count") do
      post(
        dashboard_posts_url,
        params: {
          post: {
            title: "Some good title",
            body_markdown: "Some long body text",
            slug: "some-good-title",
            published: true,
            published_at: DateTime.now
          }
        }
      )
    end

    # Redirects to dashboard after creation according to Dashboard::PostsController
    assert_redirected_to dashboard_url
  end

  test "should get edit" do
    post session_url, params: { email_address: @user.email_address, password: "password" }
    get edit_dashboard_post_url(@post)
    assert_response :success
  end

  test "should update post" do
    post session_url, params: { email_address: @user.email_address, password: "password" }
    patch(
      dashboard_post_url(@post),
      params: { post: { body_markdown: "Updated body", published: @post.published, published_at: @post.published_at, title: @post.title } }
    )
    assert_redirected_to dashboard_url
  end

  test "should destroy post" do
    post session_url, params: { email_address: @user.email_address, password: "password" }
    assert_difference("Post.count", -1) do
      delete dashboard_post_url(@post)
    end

    assert_redirected_to dashboard_url
  end

  test "should redirect new when not logged in" do
    delete session_url if defined?(session[:user_id])
    get new_dashboard_post_url
    assert_redirected_to new_session_url
  end

  test "should redirect create when not logged in" do
    delete session_url if defined?(session[:user_id])
    assert_no_difference("Post.count") do
      post dashboard_posts_url, params: { post: { body_markdown: "Test Body", title: "Test Title" } }
    end
    assert_redirected_to new_session_url
  end

  test "should redirect edit when not logged in" do
    delete session_url if defined?(session[:user_id])
    get edit_dashboard_post_url(@post)
    assert_redirected_to new_session_url
  end

  test "should redirect update when not logged in" do
    delete session_url if defined?(session[:user_id])
    patch dashboard_post_url(@post), params: { post: { body_markdown: "Updated Body", title: "Updated Title" } }
    assert_redirected_to new_session_url
  end

  test "should redirect destroy when not logged in" do
    delete session_url if defined?(session[:user_id])
    assert_no_difference("Post.count") do
      delete dashboard_post_url(@post)
    end
    assert_redirected_to new_session_url
  end
end
