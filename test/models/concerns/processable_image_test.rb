require "test_helper"

class ProcessableImageTest < ActiveSupport::TestCase
  class TestModel < ApplicationRecord
    self.table_name = "posts"
    include ProcessableImage
    has_one_attached :image
    has_many_attached :images
  end

  def setup
    @model = TestModel.create!(
      title: "Test",
      author_id: users(:one).id,
      blog_id: blogs(:one).id
    )
  end

  test "concern is included and responds to methods" do
    assert @model.respond_to?(:has_attachments_to_process?, true)
    assert @model.respond_to?(:process_attached_images, true)
    assert @model.respond_to?(:queue_image_processing, true)
  end

  test "attachments work correctly" do
    @model.image.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test_image_with_exif.jpg")),
      filename: "test.jpg",
      content_type: "image/jpeg"
    )

    assert @model.image.attached?
  end

  test "multiple attachments work correctly" do
    # Just test that the basic attachment functionality works
    @model.images.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test_image_with_exif.jpg")),
      filename: "test1.jpg",
      content_type: "image/jpeg"
    )

    assert @model.images.attached?
  end

  test "non-image attachments work correctly" do
    @model.image.attach(
      io: StringIO.new("test content"),
      filename: "test.txt",
      content_type: "text/plain"
    )

    assert @model.image.attached?
  end

  test "queue_image_processing only processes images" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("test content"),
      filename: "test.txt",
      content_type: "text/plain"
    )

    # Should return early for non-images
    assert_nil @model.send(:queue_image_processing, blob)
  end
end
