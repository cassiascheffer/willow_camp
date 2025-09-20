require "test_helper"
require "ruby-vips"

class ImageProcessingJobTest < ActiveJob::TestCase
  def setup
    @blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test/fixtures/files/test_image_with_exif.jpg")),
      filename: "test_image.jpg",
      content_type: "image/jpeg"
    )
  end

  test "processes image blob successfully" do
    assert_nil @blob.metadata["processed"]

    ImageProcessingJob.perform_now(@blob.id)

    @blob.reload
    assert @blob.metadata["processed"]
  end

  test "skips non-image files" do
    text_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("test content"),
      filename: "test.txt",
      content_type: "text/plain"
    )

    ImageProcessingJob.perform_now(text_blob.id)

    text_blob.reload
    assert_nil text_blob.metadata["processed"]
  end

  test "skips already processed images" do
    @blob.update!(metadata: @blob.metadata.merge("processed" => true))

    # Record the initial metadata state
    initial_metadata = @blob.metadata.dup

    ImageProcessingJob.perform_now(@blob.id)

    @blob.reload
    # Metadata should remain unchanged
    assert_equal initial_metadata, @blob.metadata
    assert @blob.metadata["processed"]
  end

  test "handles missing blobs gracefully" do
    assert_nothing_raised do
      ImageProcessingJob.perform_now(999999)
    end
  end

  test "re-raises errors for retry" do
    # Create a blob with invalid image data to trigger an error
    bad_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("not an image"),
      filename: "bad.jpg",
      content_type: "image/jpeg"
    )

    # This should raise an error when trying to process the invalid image
    assert_raises(Vips::Error) do
      ImageProcessingJob.perform_now(bad_blob.id)
    end
  end
end
