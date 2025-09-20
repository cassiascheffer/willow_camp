# ABOUTME: Service class that handles image processing - removes EXIF data and optimizes file size
# ABOUTME: Works with Active Storage blobs to create optimized variants without metadata

class ImageProcessor
  require "image_processing/mini_magick"

  attr_reader :blob

  def initialize(blob)
    @blob = blob
  end

  def process!
    return unless processable?

    # Download the original file
    blob.open do |tempfile|
      # Process the image
      processed_file = process_image(tempfile.path)

      # Upload the processed version back
      blob.upload(processed_file)

      # Clean up
      processed_file.close!
    end

    # Create optimized variants
    create_optimized_variants
  end

  private

  def processable?
    # Only process image types
    blob.content_type.start_with?("image/") && blob.byte_size.positive?
  end

  def process_image(source_path)
    pipeline = ImageProcessing::MiniMagick.source(source_path)

    # Strip EXIF data and optimize based on format
    pipeline = case blob.content_type
    when "image/jpeg", "image/jpg"
      pipeline
        .strip # Remove all EXIF data
        .quality(85) # Optimize JPEG quality
        .interlace("Plane") # Progressive JPEG
    when "image/png"
      pipeline
        .strip # Remove all metadata
        .quality(95) # PNG compression
    when "image/gif"
      pipeline
        .strip # Remove metadata
    when "image/webp"
      pipeline
        .strip # Remove metadata
        .quality(85) # WebP quality
    else
      # Default processing for other formats
      pipeline.strip
    end

    # Apply auto-orient to fix rotation issues from removed EXIF
    pipeline = pipeline.auto_orient

    # Process and return tempfile
    pipeline.call
  end

  def create_optimized_variants
    # Skip variant creation for non-variable images (like GIFs)
    return unless blob.variable?

    # Store variant metadata to indicate they're available
    metadata_updates = {}

    %w[thumb medium large].each do |variant_name|
      metadata_key = "variant_#{variant_name}"
      metadata_updates[metadata_key] = true unless blob.metadata[metadata_key]
    end

    # Update metadata if there are new variants
    if metadata_updates.any?
      blob.update!(metadata: blob.metadata.merge(metadata_updates))
    end
  rescue => e
    Rails.logger.error "Failed to create variants for blob #{blob.id}: #{e.message}"
    # Don't fail the whole job if variant creation fails
  end
end
