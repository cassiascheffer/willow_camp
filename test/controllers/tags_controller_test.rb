require "test_helper"

class TagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @post = posts(:one)

    # Create a test tag with spaces
    @tag = ActsAsTaggableOn::Tag.create!(name: "Test Tag With Spaces")
    # Tag the post
    @post.tag_list.add(@tag.name)
    @post.save

    # Set up host headers for subdomain-based testing
    @headers = {host: "#{@user.subdomain}.example.com"}
  end

  test "should get index" do
    get tags_url, headers: @headers
    assert_response :success
  end

  test "should show tag" do
    get tag_url(@tag.slug), headers: @headers
    assert_response :success
  end
end
