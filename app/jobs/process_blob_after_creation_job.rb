# ABOUTME: Job to handle image processing for direct uploads after blob creation
# ABOUTME: Replaces the antipattern of class_eval on ActiveStorage::Blob

class ProcessBlobAfterCreationJob < ApplicationJob
  queue_as :default

  def perform(blob_id)
    blob = ActiveStorage::Blob.find(blob_id)

    # Only process images
    return unless blob.content_type&.start_with?("image/")

    # Skip if already processed or queued
    return if blob.metadata["processed"] || blob.metadata["processing_queued"]

    # Mark as queued to prevent duplicate processing
    blob.update!(metadata: blob.metadata.merge("processing_queued" => true))

    # Queue the actual processing job
    ImageProcessingJob.perform_later(blob.id)
    Rails.logger.info "Queued image processing for blob #{blob.id} (direct upload)"
  rescue ActiveRecord::RecordNotFound
    # Blob was deleted before we could process it
    Rails.logger.info "ProcessBlobAfterCreationJob: Blob #{blob_id} not found, skipping"
  rescue => e
    Rails.logger.error "Failed to queue image processing for blob #{blob_id}: #{e.message}"
  end
end
