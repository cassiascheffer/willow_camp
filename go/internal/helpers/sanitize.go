package helpers

import (
	"fmt"
	"strings"

	"github.com/microcosm-cc/bluemonday"
	"golang.org/x/net/html"
)

// SanitizeHTMLForFeed sanitizes HTML content for RSS/Atom/JSON feeds
// It removes unsafe tags/attributes and converts relative anchor links to absolute URLs
func SanitizeHTMLForFeed(htmlContent, protocol, host string, port int, path string) string {
	// Create a policy that allows specific safe tags and attributes
	policy := bluemonday.NewPolicy()

	// Allow safe tags
	policy.AllowElements("a", "b", "strong", "i", "em", "p", "h1", "h2", "h3", "h4", "h5", "h6",
		"ul", "ol", "li", "blockquote", "pre", "code", "img")

	// Allow specific attributes
	policy.AllowAttrs("href").OnElements("a")
	policy.AllowAttrs("src", "alt", "title").OnElements("img")

	// Sanitize the content
	sanitized := policy.Sanitize(htmlContent)

	// Convert relative anchor links to absolute URLs
	sanitized = convertAnchorLinks(sanitized, protocol, host, port, path)

	return sanitized
}

// convertAnchorLinks converts relative anchor links (#section) to absolute URLs
func convertAnchorLinks(htmlContent, protocol, host string, port int, path string) string {
	// Parse the HTML
	doc, err := html.Parse(strings.NewReader(htmlContent))
	if err != nil {
		return htmlContent
	}

	// Build base URL
	baseURL := fmt.Sprintf("%s%s", protocol, host)
	if port != 80 && port != 443 && port != 0 {
		baseURL = fmt.Sprintf("%s:%d", baseURL, port)
	}

	// Recursively find and update anchor links
	var f func(*html.Node)
	f = func(n *html.Node) {
		if n.Type == html.ElementNode && n.Data == "a" {
			for i, attr := range n.Attr {
				if attr.Key == "href" && strings.HasPrefix(attr.Val, "#") {
					// Convert #section to https://example.com/path#section
					n.Attr[i].Val = fmt.Sprintf("%s%s%s", baseURL, path, attr.Val)
				}
			}
		}
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			f(c)
		}
	}
	f(doc)

	// Render back to HTML
	var buf strings.Builder
	err = html.Render(&buf, doc)
	if err != nil {
		return htmlContent
	}

	// Extract just the body content (html.Render adds <html><head></head><body>...</body></html>)
	result := buf.String()
	// Remove the wrapper tags
	result = strings.TrimPrefix(result, "<html><head></head><body>")
	result = strings.TrimSuffix(result, "</body></html>")

	return result
}
