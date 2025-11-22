#!/bin/bash
set -e

# Script to fetch heroicons from GitHub and save as Go template partials
# Usage: ./scripts/fetch-heroicons.sh

HEROICONS_BASE="https://raw.githubusercontent.com/tailwindlabs/heroicons/master/src"
ICONS_DIR="internal/templates/icons"

# Create icons directory structure
mkdir -p "$ICONS_DIR/24/outline"
mkdir -p "$ICONS_DIR/24/solid"
mkdir -p "$ICONS_DIR/20/solid"
mkdir -p "$ICONS_DIR/16/solid"

echo "Fetching heroicons..."

# Define icons to fetch
# Format: "size/type/name"
declare -a icons=(
    # 24px outline icons
    "24/outline/bars-3"
    "24/outline/cog-6-tooth"
    "24/outline/user-circle"
    "24/outline/check"
    "24/outline/document"
    "24/outline/arrow-top-right-on-square"
    "24/outline/ellipsis-vertical"
    "24/outline/information-circle"
    "24/outline/chevron-down"
    "24/outline/exclamation-triangle"
    "24/outline/trash"
    "24/outline/eye"
    "24/outline/eye-slash"
    "24/outline/clipboard"
    "24/outline/envelope"
    "24/outline/user"
    "24/outline/key"

    # 20px solid icons (mini)
    "20/solid/check"
    "20/solid/plus"
    "20/solid/lock-closed"
    "20/solid/arrow-left-start-on-rectangle"
    "20/solid/arrow-left"

    # 16px solid icons (micro)
    "16/solid/pencil"
    "16/solid/trash"
)

# Fetch each icon
for icon_path in "${icons[@]}"; do
    url="$HEROICONS_BASE/$icon_path.svg"
    output="$ICONS_DIR/$icon_path.svg"

    echo "Downloading $icon_path..."
    curl -s -f "$url" -o "$output"

    if [ $? -eq 0 ]; then
        echo "✓ $icon_path"
    else
        echo "✗ Failed to download $icon_path"
        exit 1
    fi
done

echo ""
echo "Successfully fetched ${#icons[@]} icons to $ICONS_DIR"
echo ""
echo "To add more icons:"
echo "1. Add the icon path to the 'icons' array in this script"
echo "2. Run ./scripts/fetch-heroicons.sh"
