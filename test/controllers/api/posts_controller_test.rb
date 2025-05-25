require "test_helper"

class Api::PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @user_two = users(:two)
    @post = posts(:one)  # belongs to @user (one)
    @post_two = posts(:two)  # belongs to @user_two (two)
    @token = UserToken.create(user: @user, name: "Test Token").token
    @headers = {"Authorization" => "Bearer #{@token}"}
  end

  test "should not create post without authentication" do
    assert_no_difference("Post.count") do
      post api_posts_url, params: {post: {
        markdown: "---\ntitle: New Post\npublished: true\n---\n# Hello World"
      }}, as: :json
    end
    assert_response :unauthorized
  end

  test "should create post with valid authentication and data" do
    assert_difference("Post.count") do
      post api_posts_url, params: {post: {
        markdown: "---\ntitle: New Post\npublished: true\n---\n# Hello World"
      }}, headers: @headers, as: :json
    end
    assert_response :created

    json_response = JSON.parse(response.body)
    assert_includes json_response, "post"
    assert_equal "New Post", json_response["post"]["title"]

    created_post = Post.find_by(title: "New Post")
    assert_equal @user.id, created_post.author_id
  end

  test "should not create post with invalid data" do
    assert_no_difference("Post.count") do
      post api_posts_url, params: {post: {
        markdown: "---\ntitle: \n---\n# Hello World"
      }}, headers: @headers, as: :json
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

    post_ids = json_response["posts"].map { |p| p["id"] }

    assert_includes post_ids, @post.id

    assert_not_includes post_ids, @post_two.id
  end

  test "should get post by slug if owned by current user" do
    get api_post_url(slug: @post.slug), headers: @headers, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_includes json_response, "post"
    assert_equal @post.title, json_response["post"]["title"]
  end

  test "should not get post by slug if not owned by current user" do
    get api_post_url(slug: @post_two.slug), headers: @headers, as: :json
    assert_response :forbidden

    json_response = JSON.parse(response.body)
    assert_includes json_response, "error"
  end

  test "should update post" do
    patch api_post_url(slug: @post.slug),
      params: {post: {markdown: "---\ntitle: Updated Title\n---\n# Content"}},
      headers: @headers,
      as: :json
    assert_response :success

    @post.reload
    assert_equal "Updated Title", @post.title
  end

  test "should not update post without authentication" do
    patch api_post_url(slug: @post.slug),
      params: {post: {markdown: "---\ntitle: Updated Title\n---\n# Content"}},
      as: :json
    assert_response :unauthorized

    @post.reload
    assert_not_equal "Updated Title", @post.title
  end

  test "should delete post" do
    assert_difference("Post.count", -1) do
      delete api_post_url(slug: @post.slug), headers: @headers, as: :json
    end
    assert_response :no_content
  end

  test "should not delete post without authentication" do
    assert_no_difference("Post.count") do
      delete api_post_url(slug: @post.slug), as: :json
    end
    assert_response :unauthorized
  end
end
