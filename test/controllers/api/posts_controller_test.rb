require "test_helper"

class Api::PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @user_two = users(:two)
    @post = posts(:one)  # belongs to @user (one)
    @post_two = posts(:two)  # belongs to @user_two (two)
    @token = UserToken.create(user: @user).token
    @headers = { "Authorization" => "Bearer #{@token}" }
  end

  test "should not create post without authentication" do
    assert_no_difference("Post.count") do
      post api_posts_url, params: { post: {
        title: "New Post",
        body_markdown: "# Hello World",
        published: true
      } }, as: :json
    end
    assert_response :unauthorized
  end

  test "should create post with valid authentication and data" do
    assert_difference("Post.count") do
      post api_posts_url, params: { post: {
        title: "New Post",
        body_markdown: "# Hello World",
        published: true
      } }, headers: @headers, as: :json
    end
    assert_response :created

    # Verify response contains the post
    json_response = JSON.parse(response.body)
    assert_includes json_response, "post"
    assert_equal "New Post", json_response["post"]["title"]

    # Verify author is set to current user
    created_post = Post.find_by(title: "New Post")
    assert_equal @user.id, created_post.author_id
  end

  test "should not create post with invalid data" do
    assert_no_difference("Post.count") do
      post api_posts_url, params: { post: {
        title: "",
        body_markdown: "# Hello World",
        published: true
      } }, headers: @headers, as: :json
    end
    assert_response :unprocessable_entity

    # Verify response contains errors
    json_response = JSON.parse(response.body)
    assert_includes json_response, "errors"
  end

  test "should get index with only current user's posts" do
    get api_posts_url, headers: @headers, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_includes json_response, "posts"
    assert_instance_of Array, json_response["posts"]

    # Verify only posts belonging to the current user are returned
    post_ids = json_response["posts"].map { |p| p["id"] }

    # Should include the user's own post
    assert_includes post_ids, @post.id

    # Should not include other users' posts
    assert_not_includes post_ids, @post_two.id
  end

  test "should get post by slug if owned by current user" do
    get api_post_url(id: @post.slug), headers: @headers, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_includes json_response, "post"
    assert_equal @post.title, json_response["post"]["title"]
  end

  test "should not get post by slug if not owned by current user" do
    get api_post_url(id: @post_two.slug), headers: @headers, as: :json
    assert_response :forbidden

    json_response = JSON.parse(response.body)
    assert_includes json_response, "error"
  end

  test "should update post" do
    patch api_post_url(id: @post.slug),
          params: { post: { title: "Updated Title" } },
          headers: @headers,
          as: :json
    assert_response :success

    # Verify post was updated
    @post.reload
    assert_equal "Updated Title", @post.title
  end

  test "should not update post without authentication" do
    patch api_post_url(id: @post.slug),
          params: { post: { title: "Updated Title" } },
          as: :json
    assert_response :unauthorized

    # Verify post was not updated
    @post.reload
    assert_not_equal "Updated Title", @post.title
  end

  test "should delete post" do
    assert_difference("Post.count", -1) do
      delete api_post_url(id: @post.slug), headers: @headers, as: :json
    end
    assert_response :no_content
  end

  test "should not delete post without authentication" do
    assert_no_difference("Post.count") do
      delete api_post_url(id: @post.slug), as: :json
    end
    assert_response :unauthorized
  end
end
