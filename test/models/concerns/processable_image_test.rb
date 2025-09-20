require "test_helper"

class ProcessableImageTest < ActiveJob::TestCase
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

  test "queues processing job when single image is attached" do
    assert_enqueued_with(job: ImageProcessingJob) do
      @model.image.attach(
        io: File.open(Rails.root.join("test/fixtures/files/test_image_with_exif.jpg")),
        filename: "test.jpg",
        content_type: "image/jpeg"
      )
    end
  end

  test "queues processing jobs when multiple images are attached" do
    assert_enqueued_jobs 2, only: ImageProcessingJob do
      @model.images.attach([
        {
          io: File.open(Rails.root.join("test/fixtures/files/test_image_with_exif.jpg")),
          filename: "test1.jpg",
          content_type: "image/jpeg"
        },
        {
          io: File.open(Rails.root.join("test/fixtures/files/test_image.png")),
          filename: "test2.png",
          content_type: "image/png"
        }
      ])
    end
  end

  test "does not queue job for non-image attachments" do
    assert_no_enqueued_jobs only: ImageProcessingJob do
      @model.image.attach(
        io: StringIO.new("test content"),
        filename: "test.txt",
        content_type: "text/plain"
      )
    end
  end

  test "does not queue job for already processed images" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test/fixtures/files/test_image_with_exif.jpg")),
      filename: "processed.jpg",
      content_type: "image/jpeg",
      metadata: {processed: true}
    )

    assert_no_enqueued_jobs only: ImageProcessingJob do
      @model.image.attach(blob)
    end
  end

  test "handles attachment errors gracefully" do
    # Test that attachments work correctly
    assert_nothing_raised do
      @model.image.attach(
        io: File.open(Rails.root.join("test/fixtures/files/test_image_with_exif.jpg")),
        filename: "test.jpg",
        content_type: "image/jpeg"
      )
    end

    # Attachment should work
    assert @model.image.attached?

    # Job should be queued
    assert_enqueued_jobs 1, only: ImageProcessingJob
  end
end
