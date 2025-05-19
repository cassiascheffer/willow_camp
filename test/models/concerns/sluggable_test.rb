require "test_helper"

# Test model class that includes the Sluggable concern with custom slug source
class SluggedModelWithCustomSource < ApplicationRecord
  self.table_name = "posts" # Reuse posts table for testing

  include Sluggable
  slug_source :body_markdown

  def published?
    self[:published] || false
  end
end

# Test model class that includes the Sluggable concern
class SluggedModel < ApplicationRecord
  self.table_name = "posts" # Reuse posts table for testing

  include Sluggable

  # Add a published method to satisfy the Sluggable concern's dependency
  def published?
    self[:published] || false
  end
end

# Test subclass inheriting from a class with custom slug source
class ChildSluggedModel < SluggedModelWithCustomSource
end

class SluggableTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @model = SluggedModel.new(
      author_id: @user.id, # Required by the post table schema
      title: "Test Sluggable",
      body_markdown: "Test content"
    )
  end

  test "should set base_slug from title and set suffix to 1 for first model with that title" do
    @model.save!
    assert_equal "test-sluggable", @model.base_slug, "Base slug should be parameterized title"
    assert_equal 1, @model.slug_suffix, "Slug suffix should be 1 for first model"
    assert_equal "test-sluggable", @model.slug, "Slug should be just the base_slug for first model"
  end

  test "should increment slug_suffix for models with the same base_slug" do
    # First model with this title
    @model.save!
    assert_equal "test-sluggable", @model.base_slug
    assert_equal 1, @model.slug_suffix
    assert_equal "test-sluggable", @model.slug

    # Second model with the same title
    second_model = SluggedModel.new(
      author_id: @user.id,
      title: "Test Sluggable"
    )
    second_model.save!
    assert_equal "test-sluggable", second_model.base_slug
    assert_equal 2, second_model.slug_suffix
    assert_equal "test-sluggable-2", second_model.slug, "Slug should include suffix for subsequent models"

    # Third model with the same title
    third_model = SluggedModel.new(
      author_id: @user.id,
      title: "Test Sluggable"
    )
    third_model.save!
    assert_equal "test-sluggable", third_model.base_slug
    assert_equal 3, third_model.slug_suffix
    assert_equal "test-sluggable-3", third_model.slug
  end

  test "should validate slug uniqueness" do
    # Create a model with a specific slug
    model1 = SluggedModel.create!(
      author_id: @user.id,
      title: "Original Test Model",
      slug: "test-slug-#{SecureRandom.hex(4)}"
    )

    # Try to create another model with the same slug
    model2 = SluggedModel.new(
      author_id: @user.id,
      title: "Duplicate Slug Model",
      slug: model1.slug
    )

    # The model should auto-correct the slug to be unique
    model2.valid?
    assert_not_equal model2.slug, model1.slug, "Slug should be changed to a unique value"
    assert model2.valid?, "Model with duplicate slug should be valid after auto-correction"
  end

  test "should update base_slug when title changes for unpublished model" do
    @model.published = false
    @model.save!
    original_base_slug = @model.base_slug

    # Change title and save
    @model.title = "New Title"
    @model.save!

    assert_not_equal original_base_slug, @model.base_slug, "Base slug should change when title changes for unpublished model"
    assert_equal "new-title", @model.base_slug, "Base slug should match new parameterized title"
    assert_equal 1, @model.slug_suffix, "Slug suffix should reset to 1 with new base_slug"
    assert_equal "new-title", @model.slug
  end

  test "should not update base_slug when title changes for published model" do
    @model.published = true
    @model.save!
    original_base_slug = @model.base_slug
    original_slug = @model.slug

    # Change title and save
    @model.title = "Updated Published Title"
    @model.save!

    assert_equal original_base_slug, @model.base_slug, "Base slug should not change when title changes for published model"
    assert_equal original_slug, @model.slug, "Slug should not change when title changes for published model"
  end

  test "should correctly handle slug when model is unpublished then republished" do
    # Create a published model
    @model.published = true
    @model.save!
    original_base_slug = @model.base_slug

    # Unpublish and change title
    @model.published = false
    @model.title = "Changed While Unpublished"
    @model.save!

    # Check that base_slug is updated when unpublished
    assert_not_equal original_base_slug, @model.base_slug
    assert_equal "changed-while-unpublished", @model.base_slug

    # Republish
    @model.published = true
    @model.save!

    # Should keep the updated slug from when it was unpublished
    assert_equal "changed-while-unpublished", @model.base_slug
  end

  test "should handle deletion and maintain correct suffix sequence" do
    # Create models with same title
    model1 = SluggedModel.create!(author_id: @user.id, title: "Sequence Test")
    model2 = SluggedModel.create!(author_id: @user.id, title: "Sequence Test")
    model3 = SluggedModel.create!(author_id: @user.id, title: "Sequence Test")

    assert_equal "sequence-test", model1.slug
    assert_equal "sequence-test-2", model2.slug
    assert_equal "sequence-test-3", model3.slug

    # Delete the middle model
    model2.destroy

    # Create a new model with the same title
    model4 = SluggedModel.create!(author_id: @user.id, title: "Sequence Test")

    # Should use next suffix (4), not reuse the deleted model's suffix
    assert_equal "sequence-test-4", model4.slug
  end

  test "should handle custom slugs with numbers correctly" do
    # Create a model with a custom slug that contains numbers
    model1 = SluggedModel.create!(
      author_id: @user.id,
      title: "Title Doesn't Matter",
      slug: "watermelon-1"
    )

    assert_equal "watermelon-1", model1.base_slug
    assert_equal 1, model1.slug_suffix
    assert_equal "watermelon-1", model1.slug

    # Create another model with the same custom slug
    model2 = SluggedModel.create!(
      author_id: @user.id,
      title: "Different Title",
      slug: "watermelon-1"
    )

    assert_equal "watermelon-1", model2.base_slug
    assert_equal 2, model2.slug_suffix
    assert_equal "watermelon-1-2", model2.slug

    # Create a third model with the same custom slug
    model3 = SluggedModel.create!(
      author_id: @user.id,
      title: "Yet Another Title",
      slug: "watermelon-1"
    )

    assert_equal "watermelon-1", model3.base_slug
    assert_equal 3, model3.slug_suffix
    assert_equal "watermelon-1-3", model3.slug
  end

  test "should use default title as slug source when not specified" do
    model = SluggedModel.new(
      author_id: @user.id,
      title: "Test Title",
      body_markdown: "Test Content"
    )
    model.save!

    assert_equal :title, model.slug_source
    assert_equal "test-title", model.slug
  end

  test "should use custom field as slug source when specified" do
    model = SluggedModelWithCustomSource.new(
      author_id: @user.id,
      title: "Test Title",
      body_markdown: "Custom Slug Source"
    )
    model.save!

    assert_equal :body_markdown, model.slug_source
    assert_equal "custom-slug-source", model.slug
  end

  test "should allow class to configure custom slug source" do
    assert_equal :body_markdown, SluggedModelWithCustomSource.new.slug_source
    assert_equal :title, SluggedModel.new.slug_source
  end

  test "should update slug based on custom slug source when changed" do
    model = SluggedModelWithCustomSource.new(
      author_id: @user.id,
      title: "Test Title",
      body_markdown: "Original Content",
      published: false
    )
    model.save!
    assert_equal "original-content", model.slug

    # Update the custom slug source
    model.body_markdown = "Updated Content"
    model.save!

    assert_equal "updated-content", model.slug
  end

  test "should inherit slug_source from parent class" do
    parent = SluggedModelWithCustomSource.new(
      author_id: @user.id,
      title: "Parent Title",
      body_markdown: "Parent Content",
      published: false
    )

    child = ChildSluggedModel.new(
      author_id: @user.id,
      title: "Child Title",
      body_markdown: "Child Content",
      published: false
    )

    assert_equal :body_markdown, parent.slug_source
    assert_equal :body_markdown, child.slug_source

    parent.save!
    child.save!

    assert_equal "parent-content", parent.slug
    assert_equal "child-content", child.slug
  end

  test "should handle custom slugs that already exist" do
    # Create the first model with a custom slug
    model1 = SluggedModel.create!(
      author_id: @user.id,
      title: "First Wow",
      slug: "wow-1",
      published: true
    )
    assert_equal "wow-1", model1.slug

    # Try creating a second model with the same slug
    model2 = SluggedModel.create!(
      author_id: @user.id,
      title: "Second Wow",
      slug: "wow-1",
      published: true
    )

    # Should auto-increment the suffix
    assert_equal "wow-1-2", model2.slug
    assert_equal "wow-1", model2.base_slug
    assert_equal 2, model2.slug_suffix
  end

  test "should handle numeric slugs properly" do
    model1 = SluggedModel.create!(
      author_id: @user.id,
      title: "Numeric Test",
      slug: "123",
      published: true
    )
    assert_equal "123", model1.slug

    model2 = SluggedModel.create!(
      author_id: @user.id,
      title: "Numeric Test 2",
      slug: "123",
      published: true
    )
    assert_equal "123-2", model2.slug
    assert_equal "123", model2.base_slug
    assert_equal 2, model2.slug_suffix
  end
end
