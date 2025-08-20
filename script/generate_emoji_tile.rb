#!/usr/bin/env ruby
# ABOUTME: Script to generate a 1200x630 tiled emoji image rotated 15 degrees with gradient backgrounds
# ABOUTME: Takes an emoji code and three hex colors for gradients and background

require "fileutils"
require "optparse"

# Configuration
OUTPUT_WIDTH = 1200
OUTPUT_HEIGHT = 630
TILE_SIZE = 80  # Size to scale each emoji tile to
ROTATION_ANGLE = -15  # Counter-clockwise rotation

# Default values
options = {
  emoji_code: "1F3D5",  # camping emoji
  primary_color: "605dff",  # purple gradient (top-left)
  secondary_color: "f43098",  # pink gradient (bottom-right)
  background_color: "00d3bb"  # teal background
}

# Parse command line arguments
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("-e", "--emoji-code CODE", "Emoji code (default: 1F3D5 - camping)") do |code|
    options[:emoji_code] = code
  end

  opts.on("-p", "--primary-color HEX", "Top-left gradient color without # (default: 605dff)") do |color|
    options[:primary_color] = color
  end

  opts.on("-s", "--secondary-color HEX", "Bottom-right gradient color without # (default: f43098)") do |color|
    options[:secondary_color] = color
  end

  opts.on("-b", "--background-color HEX", "Background color without # (default: 00d3bb)") do |color|
    options[:background_color] = color
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    puts "\nExamples:"
    puts "  #{$0}  # Use all defaults"
    puts "  #{$0} -e 1F600  # Grinning face with default colors"
    puts "  #{$0} --emoji-code 1F600  # Same as above with long form"
    puts "  #{$0} -p FF0000 -s 0000FF  # Custom gradient colors"
    puts "  #{$0} -e 1F31F -b 000000  # Star emoji with black background"
    exit
  end
end.parse!

emoji_code = options[:emoji_code]
top_left_color = "##{options[:primary_color]}"
top_right_color = "##{options[:secondary_color]}"
background_color = "##{options[:background_color]}"

input_path = File.join(Dir.pwd, "public", "openmoji-618x618-color", "#{emoji_code}.png")

unless File.exist?(input_path)
  puts "Error: File not found: #{input_path}"
  puts "Please ensure emoji code #{emoji_code} exists in public/openmoji-618x618-color/"
  exit 1
end

# Calculate dimensions for the larger canvas to ensure coverage after rotation
angle_rad = ROTATION_ANGLE.abs * Math::PI / 180
sin_angle = Math.sin(angle_rad)
cos_angle = Math.cos(angle_rad)

# Calculate the dimensions needed to cover the output after rotation
# Need extra padding to account for rotation shifting content
expanded_width = (OUTPUT_WIDTH * cos_angle + OUTPUT_HEIGHT * sin_angle).ceil + TILE_SIZE * 6
expanded_height = (OUTPUT_WIDTH * sin_angle + OUTPUT_HEIGHT * cos_angle).ceil + TILE_SIZE * 6

# Calculate grid dimensions - add more rows to ensure full coverage
cols = (expanded_width.to_f / TILE_SIZE).ceil + 4
rows = (expanded_height.to_f / (TILE_SIZE * 0.866)).ceil + 8  # 0.866 for vertical spacing in hex pattern, +8 for extra coverage

# Output filename
output_filename = "tiled_#{File.basename(emoji_code, ".*")}_#{OUTPUT_WIDTH}x#{OUTPUT_HEIGHT}.png"
output_path = File.join(Dir.pwd, "public", output_filename)

# Create temp files
temp_emoji = "/tmp/temp_emoji_#{Process.pid}.png"
temp_tiled = "/tmp/temp_tiled_#{Process.pid}.png"
temp_background = "/tmp/temp_background_#{Process.pid}.png"
temp_gradient1 = "/tmp/temp_gradient1_#{Process.pid}.png"
temp_gradient2 = "/tmp/temp_gradient2_#{Process.pid}.png"
temp_combined_bg = "/tmp/temp_combined_bg_#{Process.pid}.png"

# Create the background with gradients
# Step 1: Create solid background
system("magick -size #{OUTPUT_WIDTH}x#{OUTPUT_HEIGHT} xc:'#{background_color}' '#{temp_background}'")

# Step 2: Create radial gradient from top-left corner
# Create gradient centered at 0,0 (top-left) with half the diagonal as radius
radius = Math.sqrt(OUTPUT_WIDTH**2 + OUTPUT_HEIGHT**2).to_i / 2
system("magick -size #{OUTPUT_WIDTH}x#{OUTPUT_HEIGHT} xc:none -sparse-color barycentric '0,0 #{top_left_color} #{radius},#{radius} none' '#{temp_gradient1}'")

# Step 3: Create radial gradient from bottom-right corner
# Create gradient centered at bottom-right with half the diagonal as radius
system("magick -size #{OUTPUT_WIDTH}x#{OUTPUT_HEIGHT} xc:none -sparse-color barycentric '#{OUTPUT_WIDTH - 1},#{OUTPUT_HEIGHT - 1} #{top_right_color} #{OUTPUT_WIDTH - radius},#{OUTPUT_HEIGHT - radius} none' '#{temp_gradient2}'")

# Step 4: Combine background with gradients
system("magick '#{temp_background}' '#{temp_gradient1}' -compose over -composite '#{temp_gradient2}' -compose over -composite '#{temp_combined_bg}'")

# Resize the emoji
system("magick '#{input_path}' -resize #{TILE_SIZE}x#{TILE_SIZE} '#{temp_emoji}'")

# Build the magick command for creating the tiled pattern
convert_cmd = ["magick", "-size", "#{expanded_width}x#{expanded_height}", "xc:transparent"]

# Add each emoji tile with offset pattern
rows.times do |row|
  cols.times do |col|
    x_pos = col * TILE_SIZE
    # Offset every other row by half tile width for hexagonal pattern
    x_pos += TILE_SIZE / 2 if row % 2 == 1
    y_pos = (row * TILE_SIZE * 0.866).to_i

    # Don't skip any tiles - let them overflow if needed for full coverage

    # Add this emoji to the composite command
    convert_cmd += ["'#{temp_emoji}'", "-geometry", "+#{x_pos}+#{y_pos}", "-composite"]
  end
end

# Add the output file
convert_cmd << "'#{temp_tiled}'"

# Execute the tiling command
system(convert_cmd.join(" "))

# Rotate the emoji layer
temp_rotated = "/tmp/temp_rotated_#{Process.pid}.png"
system("magick '#{temp_tiled}' -background transparent -rotate #{ROTATION_ANGLE} -gravity center -crop #{OUTPUT_WIDTH}x#{OUTPUT_HEIGHT}+0+0 +repage '#{temp_rotated}'")

# Combine background with rotated emoji layer
system("magick '#{temp_combined_bg}' '#{temp_rotated}' -compose over -composite '#{output_path}'")

# Clean up temp files
[temp_emoji, temp_tiled, temp_background, temp_gradient1, temp_gradient2, temp_combined_bg, temp_rotated].each do |file|
  File.delete(file) if File.exist?(file)
end

# Run pngcrush to optimize the output
temp_crushed = "/tmp/temp_crushed_#{Process.pid}.png"
if system("which pngcrush > /dev/null 2>&1")
  print "Optimizing with pngcrush..."
  if system("pngcrush -q '#{output_path}' '#{temp_crushed}' 2>/dev/null")
    original_size = File.size(output_path)
    File.rename(temp_crushed, output_path)
    new_size = File.size(output_path)
    savings = ((original_size - new_size) / original_size.to_f * 100).round(1)
    puts " saved #{savings}% (#{original_size} → #{new_size} bytes)"
  else
    puts " failed, using unoptimized image"
    File.delete(temp_crushed) if File.exist?(temp_crushed)
  end
else
  puts "Note: pngcrush not found, skipping optimization"
end

puts "Generated: #{output_path}"
puts "Settings:"
puts "  Emoji: #{emoji_code} (#{(emoji_code == "1F3D5") ? "camping" : "custom"})"
puts "  Primary color (top-left): #{top_left_color}"
puts "  Secondary color (bottom-right): #{top_right_color}"
puts "  Background: #{background_color}"
