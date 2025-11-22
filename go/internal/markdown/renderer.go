package markdown

import (
	"bytes"
	"html/template"

	"github.com/yuin/goldmark"
	highlighting "github.com/yuin/goldmark-highlighting/v2"
	"github.com/yuin/goldmark/extension"
	"github.com/yuin/goldmark/parser"
	"github.com/yuin/goldmark/renderer/html"
)

var md goldmark.Markdown

func init() {
	md = goldmark.New(
		goldmark.WithExtensions(
			extension.GFM,        // GitHub Flavored Markdown
			extension.Table,      // Tables
			extension.Strikethrough,
			extension.Linkify,    // Auto-link URLs
			extension.TaskList,   // Task lists
			highlighting.NewHighlighting(
				highlighting.WithStyle("monokai"),
			),
		),
		goldmark.WithParserOptions(
			parser.WithAutoHeadingID(), // Auto-generate heading IDs
		),
		goldmark.WithRendererOptions(
			html.WithHardWraps(), // Render line breaks as <br>
			html.WithXHTML(),     // XHTML-compatible output
		),
	)
}

// Render converts markdown to HTML
func Render(source string) (template.HTML, error) {
	var buf bytes.Buffer
	if err := md.Convert([]byte(source), &buf); err != nil {
		return "", err
	}
	return template.HTML(buf.String()), nil
}

// RenderString is a convenience function that returns a string
func RenderString(source string) (string, error) {
	var buf bytes.Buffer
	if err := md.Convert([]byte(source), &buf); err != nil {
		return "", err
	}
	return buf.String(), nil
}
