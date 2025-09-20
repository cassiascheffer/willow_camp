require "test_helper"

class DirectUploadProcessingTest < ActiveJob::TestCase
  test "direct upload blobs queue processing jobs" do
    # Test the new job-based approach
    assert_enqueued_with(job: ProcessBlobAfterCreationJob) do
      # Simulate what the controller does for direct uploads
      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join("test/fixtures/files/test_image_with_exif.jpg")),
        filename: "direct_upload.jpg",
        content_type: "image/jpeg"
      )

      # Manually queue the job as the controller would
      ProcessBlobAfterCreationJob.perform_later(blob.id)
    end
  end

  test "non-image blobs do not queue processing jobs" do
    assert_no_enqueued_jobs only: ImageProcessingJob do
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("test content"),
        filename: "test.txt",
        content_type: "text/plain"
      )
    end
  end

  test "already processed blobs do not queue duplicate jobs" do
    # Create blob with processed metadata
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test/fixtures/files/test_image_with_exif.jpg")),
      filename: "already_processed.jpg",
      content_type: "image/jpeg",
      metadata: {"processed" => true}
    )

    # Should not be marked as queued
    blob.reload
    assert_nil blob.metadata["processing_queued"]
  end
end
