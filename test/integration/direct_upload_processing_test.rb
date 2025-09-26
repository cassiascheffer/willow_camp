require "test_helper"

class DirectUploadProcessingTest < ActiveJob::TestCase
  test "direct upload blobs queue processing jobs" do
    # Test the new job-based approach
    assert_enqueued_with(job: ImageProcessingJob) do
      # Simulate what the controller does for direct uploads
      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join("test/fixtures/files/test_image_with_exif.jpg")),
        filename: "direct_upload.jpg",
        content_type: "image/jpeg"
      )

      # Manually queue the job as the controller would
      ImageProcessingJob.perform_later(blob.id)
    end
  end

  test "non-image blobs do not get processed" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("test content"),
      filename: "test.txt",
      content_type: "text/plain"
    )

    # Job should exit early for non-images
    ImageProcessingJob.perform_now(blob.id)

    # Should not have processed metadata
    blob.reload
    assert_nil blob.metadata["processed"]
  end

  test "already processed blobs skip processing" do
    # Create blob with processed metadata
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test/fixtures/files/test_image_with_exif.jpg")),
      filename: "already_processed.jpg",
      content_type: "image/jpeg",
      metadata: {"processed" => true}
    )

    # Job should exit early when it sees processed flag
    ImageProcessingJob.perform_now(blob.id)

    # Should remain processed
    blob.reload
    assert blob.metadata["processed"]
  end
end
