# ABOUTME: Background job to process uploaded images - removes EXIF data and optimizes file size
# ABOUTME: Queues image processing tasks for Active Storage attachments to run asynchronously

class ImageProcessingJob < ApplicationJob
  queue_as :default

  def perform(blob_id)
    blob = ActiveStorage::Blob.find(blob_id)
    return unless blob.content_type.start_with?("image/")

    return if blob.metadata["processed"]

    processor = ImageProcessor.new(blob)
    processor.process!

    blob.update!(metadata: blob.metadata.merge("processed" => true, "processing_queued" => false))
  rescue ActiveRecord::RecordNotFound
    Rails.logger.info "ImageProcessingJob: Blob #{blob_id} not found, skipping"
  rescue => e
    Rails.logger.error "ImageProcessingJob: Error processing blob #{blob_id}: #{e.message}"
    raise
  end
end
