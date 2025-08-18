#!/bin/bash
# ABOUTME: Script to resize emoji PNG images from 72x72 to 32x32 and convert to ICO format
# ABOUTME: Uses ImageMagick to maintain quality during resize and format conversion

# Check if ImageMagick is installed
if ! command -v magick &> /dev/null && ! command -v convert &> /dev/null; then
    echo "Error: ImageMagick is not installed."
    echo "Please install it using: brew install imagemagick"
    exit 1
fi

# Set paths
SOURCE_DIR="app/assets/images/images/openmoji-72x72-color"
OUTPUT_DIR="app/assets/images/images/openmoji-32x32-ico"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Count total files for progress tracking
TOTAL_FILES=$(find "$SOURCE_DIR" -name "*.png" -type f | wc -l | tr -d ' ')
CURRENT=0

echo "Starting conversion of $TOTAL_FILES emoji files..."
echo "Source: $SOURCE_DIR"
echo "Output: $OUTPUT_DIR"
echo ""

# Process each PNG file
for png_file in "$SOURCE_DIR"/*.png; do
    if [ -f "$png_file" ]; then
        # Get the filename without path
        filename=$(basename "$png_file")
        # Remove .png extension and add .ico
        ico_filename="${filename%.png}.ico"
        
        # Increment counter
        ((CURRENT++))
        
        # Show progress
        echo "[$CURRENT/$TOTAL_FILES] Converting: $filename -> $ico_filename"
        
        # Use ImageMagick to resize and convert
        # -resize 32x32 : Resize to 32x32 pixels
        # -filter Lanczos : Use high-quality Lanczos filter for resize
        # -density 72 : Set DPI for clarity
        # -background transparent : Preserve transparency
        # -alpha on : Enable alpha channel
        # -define icon:auto-resize=32 : Ensure ICO is 32x32
        if command -v magick &> /dev/null; then
            # ImageMagick 7.x
            magick "$png_file" \
                -resize 32x32 \
                -filter Lanczos \
                -density 72 \
                -background transparent \
                -alpha on \
                -define icon:auto-resize=32 \
                "$OUTPUT_DIR/$ico_filename"
        else
            # ImageMagick 6.x
            convert "$png_file" \
                -resize 32x32 \
                -filter Lanczos \
                -density 72 \
                -background transparent \
                -alpha on \
                -define icon:auto-resize=32 \
                "$OUTPUT_DIR/$ico_filename"
        fi
        
        # Check if conversion was successful
        if [ $? -ne 0 ]; then
            echo "  ⚠️  Failed to convert: $filename"
        fi
    fi
done

echo ""
echo "✅ Conversion complete!"
echo "Output files saved to: $OUTPUT_DIR"

# Show statistics
OUTPUT_COUNT=$(find "$OUTPUT_DIR" -name "*.ico" -type f | wc -l | tr -d ' ')
echo "Successfully converted: $OUTPUT_COUNT files"

if [ "$OUTPUT_COUNT" -ne "$TOTAL_FILES" ]; then
    FAILED=$((TOTAL_FILES - OUTPUT_COUNT))
    echo "⚠️  Warning: $FAILED files failed to convert"
fi