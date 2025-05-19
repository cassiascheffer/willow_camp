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
    puts request.inspect
    assert_response :success
  end

  test "should show post" do
    get post_url(@post), headers: @headers
    assert_response :success
  end

  test "should get new when signed in" do
    sign_in(@user)
    get new_post_url, headers: @headers
    assert_response :success
  end

  test "should create post when signed in" do
    sign_in(@user)
    assert_difference("Post.count") do
      post(
        posts_url,
        params: {
          post: {
            title: "Some good title",
            body: "Some long body text",
            slug: "some-good-title",
            published: true,
            published_at: DateTime.now
          }
        },
        headers: @headers
      )
    end

    assert_redirected_to post_url(Post.last)
  end

  test "should get edit" do
    sign_in(@user)
    get edit_post_url(@post), headers: @headers
    assert_response :success
  end

  test "should update post" do
    sign_in(@user)
    patch(
      post_url(@post),
      params: { post: { body: @post.body, published: @post.published, published_at: @post.published_at, title: @post.title } },
      headers: @headers
    )
    assert_redirected_to post_url(@post)
  end

  test "should destroy post" do
    sign_in(@user)
    assert_difference("Post.count", -1) do
      delete post_url(@post), headers: @headers
    end

    assert_redirected_to posts_url
  end

  test "should redirect new when not logged in" do
    sign_out @user
    get new_post_url, headers: @headers
    assert_redirected_to new_session_url
  end

  test "should redirect create when not logged in" do
    sign_out @user
    assert_no_difference("Post.count") do
      post posts_url, params: { post: { body: "Test Body", title: "Test Title" } }, headers: @headers
    end
    assert_redirected_to new_session_url
  end

  test "should redirect edit when not logged in" do
    sign_out @user
    get edit_post_url(@post), headers: @headers
    assert_redirected_to new_session_url
  end

  test "should redirect update when not logged in" do
    sign_out @user
    patch post_url(@post), params: { post: { body: "Updated Body", title: "Updated Title" } }, headers: @headers
    assert_redirected_to new_session_url
  end

  test "should redirect destroy when not logged in" do
    sign_out @user
    assert_no_difference("Post.count") do
      delete post_url(@post), headers: @headers
    end
    assert_redirected_to new_session_url
  end
end
