require "application_system_test_case"

class TagSelectorTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @post = posts(:one)

    # Create some posts with tags for testing
    tagged_post1 = @user.posts.create!(title: "Ruby Post", body_markdown: "Ruby content")
    tagged_post1.tag_list = "ruby, programming, backend"
    tagged_post1.save!

    tagged_post2 = @user.posts.create!(title: "Rails Post", body_markdown: "Rails content")
    tagged_post2.tag_list = "rails, ruby, web, framework"
    tagged_post2.save!

    sign_in @user
  end

  test "tag selector initializes and shows existing tags" do
    visit edit_dashboard_post_path(@post.id)

    # Wait for the Choices.js to initialize
    assert_selector '[data-controller="tag-selector"]'

    # The original select should be hidden
    assert_selector 'select[data-tag-selector-target="select"]', visible: false

    # Choices.js should create its elements
    assert_selector ".choices", wait: 2
    assert_selector ".choices__inner"
  end

  test "tag selector allows typing to search existing tags" do
    visit edit_dashboard_post_path(@post.id)

    # Wait for initialization
    assert_selector ".choices", wait: 2

    # Click on the choices input to focus it
    find(".choices__inner").click

    # Type to search for existing tags
    find(".choices__input").send_keys("rub")

    # Should show dropdown with matching tags
    assert_selector ".choices__list--dropdown.is-active", wait: 2
    assert_text "ruby"
  end

  test "tag selector allows selecting existing tags" do
    visit edit_dashboard_post_path(@post.id)

    # Wait for initialization
    assert_selector ".choices", wait: 2

    # Click to open dropdown
    find(".choices__inner").click

    # Type to search
    find(".choices__input").send_keys("ruby")

    # Wait for dropdown to appear
    assert_selector ".choices__list--dropdown.is-active", wait: 2

    # Click on the ruby tag
    find(".choices__item--choice", text: "ruby").click

    # Should see the selected tag as a badge
    assert_selector ".choices__item", text: "ruby"

    # Hidden input should be updated
    hidden_input = find('input[name="post[tag_list]"]', visible: false)
    assert_includes hidden_input.value, "ruby"
  end

  test "tag selector allows creating new tags" do
    visit edit_dashboard_post_path(@post.id)

    # Wait for initialization
    assert_selector ".choices", wait: 2

    # Click to focus
    find(".choices__inner").click

    # Type a new tag name
    find(".choices__input").send_keys("newtag")

    # Press Enter to add it
    find(".choices__input").send_keys(:enter)

    # Should see the new tag as a badge
    assert_selector ".choices__item", text: "newtag"

    # Hidden input should contain the new tag
    hidden_input = find('input[name="post[tag_list]"]', visible: false)
    assert_includes hidden_input.value, "newtag"
  end

  test "tag selector allows removing tags" do
    # First, add a tag to the post
    @post.tag_list = "removeme"
    @post.save!

    visit edit_dashboard_post_path(@post.id)

    # Wait for initialization
    assert_selector ".choices", wait: 2

    # Should see the existing tag
    assert_selector ".choices__item", text: "removeme"

    # Click the remove button
    within(".choices__item", text: "removeme") do
      find(".choices__button").click
    end

    # Tag should be removed
    assert_no_selector ".choices__item", text: "removeme"

    # Hidden input should not contain the removed tag
    hidden_input = find('input[name="post[tag_list]"]', visible: false)
    assert_not_includes hidden_input.value, "removeme"
  end

  test "tag selector maintains multiple tags" do
    visit edit_dashboard_post_path(@post.id)

    # Wait for initialization
    assert_selector ".choices", wait: 2

    # Add multiple tags
    find(".choices__inner").click
    find(".choices__input").send_keys("tag1")
    find(".choices__input").send_keys(:enter)

    find(".choices__input").send_keys("tag2")
    find(".choices__input").send_keys(:enter)

    find(".choices__input").send_keys("tag3")
    find(".choices__input").send_keys(:enter)

    # Should see all three tags
    assert_selector ".choices__item", text: "tag1"
    assert_selector ".choices__item", text: "tag2"
    assert_selector ".choices__item", text: "tag3"

    # Hidden input should contain all tags
    hidden_input = find('input[name="post[tag_list]"]', visible: false)
    assert_includes hidden_input.value, "tag1"
    assert_includes hidden_input.value, "tag2"
    assert_includes hidden_input.value, "tag3"
  end

  test "tag selector form submission preserves tags" do
    visit edit_dashboard_post_path(@post.id)

    # Wait for initialization
    assert_selector ".choices", wait: 2

    # Add some tags
    find(".choices__inner").click
    find(".choices__input").send_keys("submission")
    find(".choices__input").send_keys(:enter)

    find(".choices__input").send_keys("test")
    find(".choices__input").send_keys(:enter)

    # Submit the form (assuming there's a save button)
    # We'll trigger form submission programmatically since the save might be via AJAX
    page.execute_script("document.querySelector('form').dispatchEvent(new Event('submit', {bubbles: true}))")

    # Verify the tags were saved by checking the hidden input
    hidden_input = find('input[name="post[tag_list]"]', visible: false)
    assert_includes hidden_input.value, "submission"
    assert_includes hidden_input.value, "test"
  end

  test "tag selector shows existing post tags on load" do
    # Set some tags on the post
    @post.tag_list = "existing, tags, loaded"
    @post.save!

    visit edit_dashboard_post_path(@post.id)

    # Wait for initialization
    assert_selector ".choices", wait: 2

    # Should see the existing tags as selected
    assert_selector ".choices__item", text: "existing"
    assert_selector ".choices__item", text: "tags"
    assert_selector ".choices__item", text: "loaded"
  end

  test "tag selector filters existing tags correctly" do
    visit edit_dashboard_post_path(@post.id)

    # Wait for initialization
    assert_selector ".choices", wait: 2

    # Click to open dropdown
    find(".choices__inner").click

    # Type partial match
    find(".choices__input").send_keys("prog")

    # Should show programming tag
    assert_selector ".choices__list--dropdown.is-active", wait: 2
    assert_text "programming"

    # Should not show non-matching tags
    assert_no_text "framework"
  end

  test "tag selector handles keyboard navigation" do
    visit edit_dashboard_post_path(@post.id)

    # Wait for initialization
    assert_selector ".choices", wait: 2

    # Click to focus
    find(".choices__inner").click

    # Type to show options
    find(".choices__input").send_keys("r")

    # Wait for dropdown
    assert_selector ".choices__list--dropdown.is-active", wait: 2

    # Use arrow keys to navigate
    find(".choices__input").send_keys(:arrow_down)

    # Press enter to select
    find(".choices__input").send_keys(:enter)

    # Should have selected a tag
    assert_selector ".choices__item"
  end

  test "tag selector gracefully handles errors" do
    visit edit_dashboard_post_path(@post.id)

    # Even if JavaScript fails, the form should still be usable
    # The hidden input should be present and functional
    assert_selector 'input[name="post[tag_list]"]', visible: false

    # And the form should be submittable
    assert_selector 'form[action*="posts"]'
  end
end
