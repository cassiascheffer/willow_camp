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

    # Verify error response format
    json_response = JSON.parse(response.body)
    assert_includes json_response, "error"
    assert_equal "Unauthorized", json_response["error"]
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

    # Verify response format matches create.json.jbuilder structure
    post_data = json_response["post"]
    assert_equal "New Post", post_data["title"]
    assert_includes post_data, "id"
    assert_includes post_data, "slug"
    assert_includes post_data, "title"
    assert_includes post_data, "published"
    assert_includes post_data, "meta_description"
    assert_includes post_data, "published_at"
    assert_includes post_data, "tag_list"
    assert_includes post_data, "markdown"

    # Verify post is associated with current user
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

    # Verify response contains errors in expected format
    json_response = JSON.parse(response.body)
    assert_includes json_response, "errors"
    assert_kind_of Array, json_response["errors"]
    assert_not_empty json_response["errors"]
  end

  test "should get index with only current user's posts" do
    get api_posts_url, headers: @headers, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_includes json_response, "posts"
    assert_instance_of Array, json_response["posts"]

    # Verify format matches index.json.jbuilder structure
    json_response["posts"].each do |post|
      assert_includes post, "id"
      assert_includes post, "slug"
      assert_includes post, "markdown"
      assert post["markdown"].present?
    end

    post_ids = json_response["posts"].map { |p| p["id"] }
    post_slugs = json_response["posts"].map { |p| p["slug"] }

    # Verify only current user's posts are included
    assert_includes post_ids, @post.id
    assert_includes post_slugs, @post.slug
    assert_not_includes post_ids, @post_two.id
  end

  test "should get post by slug if owned by current user" do
    get api_post_url(slug: @post.slug), headers: @headers, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_includes json_response, "post"

    # Verify format matches show.json.jbuilder structure
    post_data = json_response["post"]
    assert_includes post_data, "id"
    assert_equal @post.id, post_data["id"]
    assert_includes post_data, "slug"
    assert_equal @post.slug, post_data["slug"]
    assert_includes post_data, "markdown"
    assert_includes post_data["markdown"], @post.title
  end

  test "should not get post by slug if not owned by current user" do
    get api_post_url(slug: @post_two.slug), headers: @headers, as: :json
    assert_response :forbidden

    json_response = JSON.parse(response.body)
    assert_includes json_response, "error"
    assert_equal "You don't have permission to access this post", json_response["error"]
  end

  test "should update post" do
    patch api_post_url(slug: @post.slug),
      params: {post: {markdown: "---\ntitle: Updated Title\n---\n# Content"}},
      headers: @headers,
      as: :json
    assert_response :success

    # Verify post was updated in database
    @post.reload
    assert_equal "Updated Title", @post.title

    # Verify response format matches update.json.jbuilder structure
    json_response = JSON.parse(response.body)
    assert_includes json_response, "post"
    post_data = json_response["post"]
    assert_includes post_data, "id"
    assert_includes post_data, "slug"
    assert_includes post_data, "title"
    assert_equal "Updated Title", post_data["title"]
    assert_includes post_data, "published"
    assert_includes post_data, "meta_description"
    assert_includes post_data, "published_at"
    assert_includes post_data, "tag_list"
    assert_includes post_data, "markdown"
  end

  test "should not update post without authentication" do
    patch api_post_url(slug: @post.slug),
      params: {post: {markdown: "---\ntitle: Updated Title\n---\n# Content"}},
      as: :json
    assert_response :unauthorized

    # Verify post was not updated in database
    @post.reload
    assert_not_equal "Updated Title", @post.title

    # Verify error response format
    json_response = JSON.parse(response.body)
    assert_includes json_response, "error"
    assert_equal "Unauthorized", json_response["error"]
  end

  test "should not update post with invalid data" do
    # Using empty title which should fail validation
    patch api_post_url(slug: @post.slug),
      params: {post: {markdown: "---\ntitle: \n---\n# Content"}},
      headers: @headers,
      as: :json
    assert_response :unprocessable_entity

    # Verify response contains errors in expected format
    json_response = JSON.parse(response.body)
    assert_includes json_response, "errors"
    assert_kind_of Array, json_response["errors"]
    assert_not_empty json_response["errors"]

    # Verify post was not updated
    @post.reload
    assert_not_equal "", @post.title
  end

  test "should delete post" do
    assert_difference("Post.count", -1) do
      delete api_post_url(slug: @post.slug), headers: @headers, as: :json
    end
    assert_response :no_content

    # Verify response body is empty as expected for no_content
    assert_empty response.body
  end

  test "should not delete post without authentication" do
    assert_no_difference("Post.count") do
      delete api_post_url(slug: @post.slug), as: :json
    end
    assert_response :unauthorized

    # Verify error response format
    json_response = JSON.parse(response.body)
    assert_includes json_response, "error"
    assert_equal "Unauthorized", json_response["error"]
  end

  test "should return not found for non-existent post" do
    get api_post_url(slug: "non-existent-post"), headers: @headers, as: :json
    assert_response :not_found

    # Verify error response format
    json_response = JSON.parse(response.body)
    assert_includes json_response, "error"
    assert_equal "Post not found", json_response["error"]
  end

  test "should not update post if not owned by current user" do
    patch api_post_url(slug: @post_two.slug),
      params: {post: {markdown: "---\ntitle: Updated Title\n---\n# Content"}},
      headers: @headers,
      as: :json
    assert_response :forbidden

    # Verify error response format
    json_response = JSON.parse(response.body)
    assert_includes json_response, "error"
    assert_equal "You don't have permission to access this post", json_response["error"]

    # Verify post was not updated
    @post_two.reload
    assert_not_equal "Updated Title", @post_two.title
  end

  test "should not delete post if not owned by current user" do
    assert_no_difference("Post.count") do
      delete api_post_url(slug: @post_two.slug), headers: @headers, as: :json
    end
    assert_response :forbidden

    # Verify error response format
    json_response = JSON.parse(response.body)
    assert_includes json_response, "error"
    assert_equal "You don't have permission to access this post", json_response["error"]
  end
end
