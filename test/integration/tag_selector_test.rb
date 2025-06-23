require "test_helper"

class TagSelectorTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @post = posts(:one)
    sign_in @user
  end

  test "tag selector form renders with correct data attributes" do
    get edit_dashboard_post_path(@post.id)
    assert_response :success

    # Check that the tag selector controller is present
    assert_select '[data-controller="tag-selector"]'

    # Check that existing tags data attribute is present
    assert_select "[data-tag-selector-existing-tags-value]"

    # Check that current tags data attribute is present
    assert_select "[data-tag-selector-current-tags-value]"

    # Check that the hidden input for tag_list is present
    assert_select 'input[type="hidden"][name="post[tag_list]"]'

    # Check that the select element is present (even if hidden)
    assert_select 'select[multiple][data-tag-selector-target="select"]'
  end

  test "tag selector includes user's existing tags in data attribute" do
    # Create a post with specific tags for this user
    tagged_post = @user.posts.create!(title: "Tagged Post", body_markdown: "Content")
    tagged_post.tag_list = "ruby, rails, testing"
    tagged_post.save!

    get edit_dashboard_post_path(@post.id)
    assert_response :success

    # Parse the existing tags from the data attribute
    tag_selector = css_select('[data-controller="tag-selector"]').first
    existing_tags_json = tag_selector.attributes["data-tag-selector-existing-tags-value"].value
    existing_tags = JSON.parse(existing_tags_json)

    assert_includes existing_tags, "ruby"
    assert_includes existing_tags, "rails"
    assert_includes existing_tags, "testing"
  end

  test "tag selector shows current post tags in data attribute" do
    # Update the post with specific tags
    @post.tag_list = "current, post, tags"
    @post.save!

    get edit_dashboard_post_path(@post.id)
    assert_response :success

    # Check that current tags are in the data attribute
    tag_selector = css_select('[data-controller="tag-selector"]').first
    current_tags = tag_selector.attributes["data-tag-selector-current-tags-value"].value

    assert_equal "current, post, tags", current_tags
  end

  test "tag_selector_handles_empty_existing_tags_gracefully" do
    # Create a post with no tags for the existing user
    untagged_post = @user.posts.create!(title: "Untagged Post", body_markdown: "Content")

    get edit_dashboard_post_path(untagged_post.id)
    assert_response :success

    # Should render with empty array for existing tags
    tag_selector = css_select('[data-controller="tag-selector"]').first
    existing_tags_json = tag_selector.attributes["data-tag-selector-existing-tags-value"].value
    existing_tags = JSON.parse(existing_tags_json)

    assert_equal [], existing_tags
  end

  test "tag_selector_handles_post_with_no_tags_gracefully" do
    # Create another post with no tags
    another_untagged_post = @user.posts.create!(title: "Another Untagged Post", body_markdown: "More content")

    get edit_dashboard_post_path(another_untagged_post.id)
    assert_response :success

    # Should render with empty string for current tags
    tag_selector = css_select('[data-controller="tag-selector"]').first
    current_tags = tag_selector.attributes["data-tag-selector-current-tags-value"].value

    assert_equal "", current_tags
  end

  test "tag list form submission works with tag selector" do
    patch dashboard_post_path(@post.id), params: {
      post: {
        title: @post.title,
        tag_list: "new, updated, tags"
      }
    }

    assert_redirected_to edit_dashboard_post_path(@post.id)

    @post.reload
    assert_equal ["new", "updated", "tags"], @post.tag_list
  end

  test "tag selector preserves other form fields" do
    get edit_dashboard_post_path(@post.id)
    assert_response :success

    # Ensure other form fields are still present
    assert_select 'input[name="post[title]"]'
    assert_select 'textarea[name="post[body_markdown]"]'
    assert_select 'input[name="post[published]"]'
    assert_select 'textarea[name="post[meta_description]"]'
  end

  test "tooltip shows correct help text for tag selector" do
    get edit_dashboard_post_path(@post.id)
    assert_response :success

    # Check that the tooltip has updated text
    assert_select '.tooltip[data-tip*="Start typing to search existing tags or create new ones"]'
  end
end
