package helpers

import (
	"fmt"
	"strings"
)

// EmojiToOpenmojiFilename converts an emoji string to its OpenMoji filename format.
// Matches the Rails helper: emoji_to_openmoji_filename
// Returns the hex codepoint representation, skipping variation selectors.
// Returns "1F3D5" (camping emoji) if emoji is blank.
func EmojiToOpenmojiFilename(emoji string) string {
	if emoji == "" {
		return "1F3D5" // Default camping emoji
	}

	runes := []rune(emoji)
	var codepoints []string

	for _, r := range runes {
		// Skip variation selectors (FE0F, FE0E)
		if r == 0xFE0F || r == 0xFE0E {
			continue
		}
		codepoints = append(codepoints, fmt.Sprintf("%X", r))
	}

	return strings.Join(codepoints, "-")
}
