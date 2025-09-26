# ABOUTME: Background job to process uploaded images - removes EXIF data and optimizes file size
# ABOUTME: Handles image processing for direct uploads from Active Storage

class ImageProcessingJob < ApplicationJob
  queue_as :default

  def perform(blob_id)
    blob = ActiveStorage::Blob.find(blob_id)

    # Only process images
    return unless blob.content_type&.start_with?("image/")

    # Skip if already processed
    return if blob.metadata["processed"]

    processor = ImageProcessor.new(blob)
    processor.process!

    blob.update!(metadata: blob.metadata.merge("processed" => true))
    Rails.logger.info "Processed image blob #{blob_id}"
  rescue ActiveRecord::RecordNotFound
    # Blob was deleted before we could process it
    Rails.logger.info "ImageProcessingJob: Blob #{blob_id} not found, skipping"
  rescue => e
    Rails.logger.error "ImageProcessingJob: Error processing blob #{blob_id}: #{e.message}"
    raise
  end
end
