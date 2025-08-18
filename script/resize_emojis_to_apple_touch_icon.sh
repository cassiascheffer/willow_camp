#!/bin/bash
# ABOUTME: Script to resize emoji PNG images from 618x618 to 180x180 and optimize with pngcrush
# ABOUTME: Creates Apple Touch Icon sized images with maximum compression

# Check if ImageMagick is installed
if ! command -v magick &> /dev/null && ! command -v convert &> /dev/null; then
    echo "Error: ImageMagick is not installed."
    echo "Please install it using: brew install imagemagick"
    exit 1
fi

# Check if pngcrush is installed
if ! command -v pngcrush &> /dev/null; then
    echo "Error: pngcrush is not installed."
    echo "Please install it using: brew install pngcrush"
    exit 1
fi

# Set paths
SOURCE_DIR="app/assets/images/images/openmoji-618x618-color"
OUTPUT_DIR="app/assets/images/images/apple-touch-icon-180x180"
TEMP_DIR="/tmp/emoji_resize_temp_$$"

# Create output and temp directories if they don't exist
mkdir -p "$OUTPUT_DIR"
mkdir -p "$TEMP_DIR"

# Count total files for progress tracking
TOTAL_FILES=$(find "$SOURCE_DIR" -name "*.png" -type f | wc -l | tr -d ' ')
CURRENT=0

echo "Starting conversion of $TOTAL_FILES emoji files..."
echo "Source: $SOURCE_DIR"
echo "Output: $OUTPUT_DIR"
echo "Temp: $TEMP_DIR"
echo ""
echo "This process includes:"
echo "1. Resizing from 618x618 to 180x180"
echo "2. Optimizing with pngcrush for minimum file size"
echo ""

# Process each PNG file
for png_file in "$SOURCE_DIR"/*.png; do
    if [ -f "$png_file" ]; then
        # Get the filename without path
        filename=$(basename "$png_file")
        
        # Increment counter
        ((CURRENT++))
        
        # Show progress
        echo "[$CURRENT/$TOTAL_FILES] Processing: $filename"
        
        # Temporary file for resized image
        temp_resized="$TEMP_DIR/${filename%.png}_resized.png"
        
        # Step 1: Resize image using ImageMagick
        # -resize 180x180 : Resize to 180x180 pixels
        # -filter Lanczos : Use high-quality Lanczos filter for resize
        # -quality 100 : Maximum quality for intermediate file
        # -background transparent : Preserve transparency
        # -alpha on : Enable alpha channel
        # -strip : Remove all metadata for smaller file
        if command -v magick &> /dev/null; then
            # ImageMagick 7.x
            magick "$png_file" \
                -resize 180x180 \
                -filter Lanczos \
                -quality 100 \
                -background transparent \
                -alpha on \
                -strip \
                "$temp_resized"
        else
            # ImageMagick 6.x
            convert "$png_file" \
                -resize 180x180 \
                -filter Lanczos \
                -quality 100 \
                -background transparent \
                -alpha on \
                -strip \
                "$temp_resized"
        fi
        
        if [ $? -ne 0 ]; then
            echo "  ⚠️  Failed to resize: $filename"
            continue
        fi
        
        # Step 2: Optimize with pngcrush
        # -brute : Try all compression methods (slower but best compression)
        # -reduce : Reduce color depth if possible without quality loss
        # -rem alla : Remove all ancillary chunks except transparency
        # -rem text : Remove text chunks
        pngcrush -brute -reduce -rem alla -rem text -q "$temp_resized" "$OUTPUT_DIR/$filename" 2>/dev/null
        
        if [ $? -ne 0 ]; then
            echo "  ⚠️  pngcrush failed, using unoptimized version: $filename"
            cp "$temp_resized" "$OUTPUT_DIR/$filename"
        fi
        
        # Clean up temporary file
        rm -f "$temp_resized"
        
        # Show size reduction every 100 files
        if [ $((CURRENT % 100)) -eq 0 ]; then
            ORIG_SIZE=$(du -sh "$SOURCE_DIR" | cut -f1)
            NEW_SIZE=$(du -sh "$OUTPUT_DIR" | cut -f1)
            echo "  📊 Progress: Original size: $ORIG_SIZE, New size: $NEW_SIZE"
        fi
    fi
done

# Clean up temp directory
rm -rf "$TEMP_DIR"

echo ""
echo "✅ Conversion complete!"
echo "Output files saved to: $OUTPUT_DIR"

# Show statistics
OUTPUT_COUNT=$(find "$OUTPUT_DIR" -name "*.png" -type f | wc -l | tr -d ' ')
echo "Successfully converted: $OUTPUT_COUNT files"

# Calculate size reduction
ORIG_SIZE=$(du -sh "$SOURCE_DIR" | cut -f1)
NEW_SIZE=$(du -sh "$OUTPUT_DIR" | cut -f1)
echo ""
echo "📦 Size comparison:"
echo "  Original (618x618): $ORIG_SIZE"
echo "  Optimized (180x180): $NEW_SIZE"

if [ "$OUTPUT_COUNT" -ne "$TOTAL_FILES" ]; then
    FAILED=$((TOTAL_FILES - OUTPUT_COUNT))
    echo "⚠️  Warning: $FAILED files failed to convert"
fi