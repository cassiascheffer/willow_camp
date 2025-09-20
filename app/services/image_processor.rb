# ABOUTME: Service class that handles image processing - removes EXIF data and optimizes file size
# ABOUTME: Works with Active Storage blobs to create optimized variants without metadata using libvips

class ImageProcessor
  require "image_processing/vips"

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
    # Process with Vips directly to have more control over metadata removal
    image = Vips::Image.new_from_file(source_path, access: :sequential)

    # Auto-rotate based on EXIF orientation
    image = image.autorot

    # Remove all metadata by creating a new image without it
    image = image.copy(interpretation: image.interpretation)

    # Create temporary file for the processed image
    temp_file = Tempfile.new(["processed", File.extname(source_path)])

    # Save with format-specific optimization
    case blob.content_type
    when "image/jpeg", "image/jpg"
      image.jpegsave(temp_file.path, Q: 85, interlace: true, strip: true)
    when "image/png"
      image.pngsave(temp_file.path, compression: 9, strip: true)
    when "image/webp"
      image.webpsave(temp_file.path, Q: 85, strip: true)
    else
      # Default to JPEG for other formats
      image.jpegsave(temp_file.path, Q: 85, strip: true)
    end

    temp_file
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
