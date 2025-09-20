# ABOUTME: Service class that handles image processing - removes EXIF data and optimizes file size
# ABOUTME: Works with Active Storage blobs to create optimized variants without metadata using libvips
require "image_processing/vips"

class ImageProcessor
  attr_reader :blob

  def initialize(blob)
    @blob = blob
  end

  def process!
    return unless processable?

    blob.open do |tempfile|
      processed_file = process_image(tempfile.path)
      blob.upload(processed_file)
      processed_file.close!
    end
  end

  private

  def processable?
    blob.content_type.start_with?("image/") && blob.byte_size.positive?
  end

  def process_image(source_path)
    image = Vips::Image.new_from_file(source_path, access: :sequential)
    image = image.autorot
    image = image.copy(interpretation: image.interpretation)
    temp_file = Tempfile.new(["processed", File.extname(source_path)])
    case blob.content_type
    when "image/jpeg", "image/jpg"
      image.jpegsave(temp_file.path, Q: 85, interlace: true, strip: true)
    when "image/png"
      image.pngsave(temp_file.path, compression: 9, strip: true)
    when "image/webp"
      image.webpsave(temp_file.path, Q: 85, strip: true)
    else
      image.jpegsave(temp_file.path, Q: 85, strip: true)
    end
    temp_file
  end
end
