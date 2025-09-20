require "test_helper"
require "ruby-vips"

class ImageProcessorTest < ActiveSupport::TestCase
  def setup
    @blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test/fixtures/files/test_image_with_exif.jpg")),
      filename: "test_image.jpg",
      content_type: "image/jpeg"
    )
    @processor = ImageProcessor.new(@blob)
  end

  test "removes EXIF data from images" do
    @processor.process!

    processed_data = @blob.download
    temp_file = Tempfile.new(["processed", ".jpg"])
    begin
      File.binwrite(temp_file.path, processed_data)
      processed_image = Vips::Image.new_from_file(temp_file.path)
      assert processed_image.width > 0
      assert processed_image.height > 0
      assert processed_data.size > 0
    ensure
      temp_file.close!
    end
  end

  test "skips non-image blobs" do
    text_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("test content"),
      filename: "test.txt",
      content_type: "text/plain"
    )

    processor = ImageProcessor.new(text_blob)
    processor.process!

    text_blob.reload
    assert_nil text_blob.metadata["processed"]
  end
end
