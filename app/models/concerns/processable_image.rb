# ABOUTME: Concern that adds image processing callbacks to Active Storage attachments
# ABOUTME: Automatically queues background jobs to remove EXIF and optimize images after upload

module ProcessableImage
  extend ActiveSupport::Concern

  included do
    after_commit :process_attached_images, if: :has_attachments_to_process?
  end

  private

  def has_attachments_to_process?
    # Check if any attachment was just added
    attachment_changes.any? do |name, change|
      change.is_a?(ActiveStorage::Attached::Changes::CreateOne) ||
        change.is_a?(ActiveStorage::Attached::Changes::CreateMany)
    end
  end

  def process_attached_images
    # Process each new attachment
    attachment_changes.each do |name, change|
      case change
      when ActiveStorage::Attached::Changes::CreateOne
        # Single attachment
        if change.blob&.persisted?
          queue_image_processing(change.blob)
        end
      when ActiveStorage::Attached::Changes::CreateMany
        # Multiple attachments
        change.blobs.each do |blob|
          queue_image_processing(blob) if blob.persisted?
        end
      end
    end
  end

  def queue_image_processing(blob)
    # Only queue processing for images
    return unless blob.content_type&.start_with?("image/")

    # Skip if already processed
    return if blob.metadata["processed"]

    ImageProcessingJob.perform_later(blob.id)
    Rails.logger.info "Queued image processing for blob #{blob.id}"
  rescue => e
    Rails.logger.error "Failed to queue image processing for blob #{blob.id}: #{e.message}"
  end
end
