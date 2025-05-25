require "test_helper"

class TagSlugTest < ActiveSupport::TestCase
  test "tags should generate slugs from name" do
    tag = ActsAsTaggableOn::Tag.create!(name: "Test Tag With Spaces")
    assert_equal "test-tag-with-spaces", tag.slug

    # Ensure we can find by slug
    found_tag = ActsAsTaggableOn::Tag.friendly.find("test-tag-with-spaces")
    assert_equal tag.id, found_tag.id
    assert_equal "Test Tag With Spaces", found_tag.name
  end
end
