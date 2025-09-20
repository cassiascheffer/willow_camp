require "test_helper"

class ProcessBlobAfterCreationJobTest < ActiveJob::TestCase
  def setup
    @blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test/fixtures/files/test_image_with_exif.jpg")),
      filename: "test_image.jpg",
      content_type: "image/jpeg"
    )
  end

  test "queues image processing job for image blobs" do
    assert_enqueued_with(job: ImageProcessingJob, args: [@blob.id]) do
      ProcessBlobAfterCreationJob.perform_now(@blob.id)
    end

    @blob.reload
    assert @blob.metadata["processing_queued"]
  end

  test "skips non-image blobs" do
    text_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("test content"),
      filename: "test.txt",
      content_type: "text/plain"
    )

    assert_no_enqueued_jobs only: ImageProcessingJob do
      ProcessBlobAfterCreationJob.perform_now(text_blob.id)
    end

    text_blob.reload
    assert_nil text_blob.metadata["processing_queued"]
  end

  test "skips already processed blobs" do
    @blob.update!(metadata: @blob.metadata.merge("processed" => true))

    assert_no_enqueued_jobs only: ImageProcessingJob do
      ProcessBlobAfterCreationJob.perform_now(@blob.id)
    end

    @blob.reload
    assert_nil @blob.metadata["processing_queued"]
  end

  test "handles missing blobs gracefully" do
    assert_nothing_raised do
      ProcessBlobAfterCreationJob.perform_now(999999)
    end
  end
end
