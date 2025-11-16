package helpers

import (
	"fmt"
	"html/template"
	"os"
	"strings"
)

// Icon loads an SVG icon from the templates/icons directory and applies the given class
func Icon(path string, class string) template.HTML {
	// Read the SVG file
	svgPath := fmt.Sprintf("internal/templates/icons/%s.svg", path)
	content, err := os.ReadFile(svgPath)
	if err != nil {
		// Return empty string if icon not found
		return template.HTML("")
	}

	svg := string(content)

	// Remove hardcoded attributes that interfere with Tailwind
	svg = removeAttribute(svg, "width")
	svg = removeAttribute(svg, "height")
	svg = removeAttribute(svg, "stroke", "#0F172A") // Remove hardcoded stroke color

	// Add or append to class attribute
	if class != "" {
		if strings.Contains(svg, `class="`) {
			// Append to existing class
			svg = strings.Replace(svg, `class="`, fmt.Sprintf(`class="%s `, class), 1)
		} else {
			// Add new class attribute
			svg = strings.Replace(svg, "<svg ", fmt.Sprintf(`<svg class="%s" `, class), 1)
		}
	}

	return template.HTML(svg)
}

// removeAttribute removes an attribute from SVG string
// If value is provided, only removes if it matches that value
func removeAttribute(svg, attr string, value ...string) string {
	if len(value) > 0 {
		// Remove only if value matches
		pattern := fmt.Sprintf(`%s="%s"`, attr, value[0])
		svg = strings.ReplaceAll(svg, pattern, "")
		// Also try without quotes for stroke-width
		pattern = fmt.Sprintf(`%s=%s`, attr, value[0])
		svg = strings.ReplaceAll(svg, pattern, "")
	} else {
		// Remove attribute regardless of value
		// Match: attr="value" or attr='value'
		start := strings.Index(svg, attr+"=")
		if start != -1 {
			// Find the quote character
			quoteStart := start + len(attr) + 1
			if quoteStart < len(svg) {
				quote := svg[quoteStart : quoteStart+1]
				// Find closing quote
				quoteEnd := strings.Index(svg[quoteStart+1:], quote)
				if quoteEnd != -1 {
					// Remove the entire attribute
					svg = svg[:start] + svg[quoteStart+quoteEnd+2:]
				}
			}
		}
	}
	return svg
}
