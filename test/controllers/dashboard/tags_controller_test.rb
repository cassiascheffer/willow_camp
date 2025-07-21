require "test_helper"

class Dashboard::TagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should get index" do
    get dashboard_tags_url
    assert_response :success
  end

  test "index shows all tags with counts including drafts" do
    published_post = @user.posts.create!(title: "Published", body_markdown: "Content", published: true)
    published_post.tag_list = "ruby, rails"
    published_post.save!

    draft_post = @user.posts.create!(title: "Draft", body_markdown: "Content", published: false)
    draft_post.tag_list = "ruby, javascript"
    draft_post.save!

    get dashboard_tags_url

    assert_response :success
    assert_select "button", text: "ruby"
    assert_select "td", text: "2" # Ruby appears in both posts
    assert_select "button", text: "rails"
    assert_select "td", text: "1" # Rails appears in published post only
    assert_select "button", text: "javascript"
    assert_select "td", text: "1" # JavaScript appears in draft only
  end

  test "index shows empty state when no tags exist" do
    get dashboard_tags_url

    assert_response :success
    assert_select ".empty-state"
    assert_select "p", text: "No tags yet"
  end

  test "index assigns all_tags_with_counts to @tags" do
    @user.posts.create!(title: "Test Post", body_markdown: "Content", published: false, tag_list: "test-tag")

    get dashboard_tags_url

    assert_response :success
    # Verify the view shows the tag from the draft post
    assert_select "button", text: "test-tag"
    assert_select "td", text: "1"
  end

  test "index table header shows 'All Posts' not 'Published Posts'" do
    @user.posts.create!(title: "Test Post", body_markdown: "Content", published: false, tag_list: "test-tag")

    get dashboard_tags_url

    assert_response :success
    assert_select "th", text: "All Posts"
    assert_select "th", text: "Published Posts", count: 0
  end

  test "should update tag name successfully" do
    post = @user.posts.create!(title: "Test Post", body_markdown: "Content", published: true)
    post.tag_list = "oldtag"
    post.save!

    tag = ActsAsTaggableOn::Tag.find_by(name: "oldtag")

    patch dashboard_tag_url(tag), params: {tag: {name: "newtag"}}, as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", @response.media_type

    tag.reload
    assert_equal "newtag", tag.name

    post.reload
    assert_includes post.tag_list, "newtag"
    assert_not_includes post.tag_list, "oldtag"
  end

  test "should return error response for invalid tag update" do
    post = @user.posts.create!(title: "Test Post", body_markdown: "Content", published: true)
    post.tag_list = "validtag"
    post.save!

    tag = ActsAsTaggableOn::Tag.find_by(name: "validtag")

    patch dashboard_tag_url(tag), params: {tag: {name: ""}}, as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", @response.media_type

    tag.reload
    assert_equal "validtag", tag.name
  end

  test "should update tag used by multiple posts" do
    post1 = @user.posts.create!(title: "Post 1", body_markdown: "Content", published: true)
    post1.tag_list = "shared, unique1"
    post1.save!

    post2 = @user.posts.create!(title: "Post 2", body_markdown: "Content", published: false)
    post2.tag_list = "shared, unique2"
    post2.save!

    tag = ActsAsTaggableOn::Tag.find_by(name: "shared")

    patch dashboard_tag_url(tag), params: {tag: {name: "updated-shared"}}, as: :turbo_stream

    assert_response :success

    tag.reload
    assert_equal "updated-shared", tag.name

    post1.reload
    post2.reload
    assert_includes post1.tag_list, "updated-shared"
    assert_includes post2.tag_list, "updated-shared"
    assert_not_includes post1.tag_list, "shared"
    assert_not_includes post2.tag_list, "shared"
  end

  test "should require authentication for update" do
    post = @user.posts.create!(title: "Test Post", body_markdown: "Content", published: true)
    post.tag_list = "testtag"
    post.save!

    tag = ActsAsTaggableOn::Tag.find_by(name: "testtag")

    sign_out @user

    patch dashboard_tag_url(tag), params: {tag: {name: "newtag"}}

    assert_redirected_to new_user_session_path
  end

  test "should only allow updating tags belonging to current user's posts" do
    other_user = users(:two)
    other_post = other_user.posts.create!(title: "Other Post", body_markdown: "Content", published: true)
    other_post.tag_list = "othertag"
    other_post.save!

    other_tag = ActsAsTaggableOn::Tag.find_by(name: "othertag")

    patch dashboard_tag_url(other_tag), params: {tag: {name: "hacked"}}, as: :turbo_stream

    assert_response :not_found
  end

  test "should delete tag successfully" do
    post = @user.posts.create!(title: "Test Post", body_markdown: "Content", published: true)
    post.tag_list = "deleteme"
    post.save!

    tag = ActsAsTaggableOn::Tag.find_by(name: "deleteme")

    delete dashboard_tag_url(tag), as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", @response.media_type
    assert_nil ActsAsTaggableOn::Tag.find_by(name: "deleteme")
  end

  test "should only allow deleting tags belonging to current user's posts" do
    other_user = users(:two)
    other_post = other_user.posts.create!(title: "Other Post", body_markdown: "Content", published: true)
    other_post.tag_list = "othertag"
    other_post.save!

    other_tag = ActsAsTaggableOn::Tag.find_by(name: "othertag")

    delete dashboard_tag_url(other_tag), as: :turbo_stream

    assert_response :not_found
  end

  test "should require authentication for delete" do
    post = @user.posts.create!(title: "Test Post", body_markdown: "Content", published: true)
    post.tag_list = "testtag"
    post.save!

    tag = ActsAsTaggableOn::Tag.find_by(name: "testtag")

    sign_out @user

    delete dashboard_tag_url(tag)

    assert_redirected_to new_user_session_path
  end
end
