#!/usr/bin/env ruby
# Script to create test images for testing

require "mini_magick"

# Change to the directory where we want to create the files
Dir.chdir(File.dirname(__FILE__))

# Create test JPEG using ImageMagick 7 syntax
system("magick -size 200x200 xc:blue test_image_with_exif.jpg")

# Create test PNG using ImageMagick 7 syntax
system("magick -size 200x200 xc:red test_image.png")

# Verify files were created
if File.exist?("test_image_with_exif.jpg") && File.exist?("test_image.png")
  puts "Test images created successfully!"
  puts "Created: test_image_with_exif.jpg (#{File.size("test_image_with_exif.jpg")} bytes)"
  puts "Created: test_image.png (#{File.size("test_image.png")} bytes)"
else
  puts "Failed to create test images"
  exit 1
end
