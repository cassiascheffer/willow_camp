package handlers

import (
	"github.com/labstack/echo/v4"
)

// DocsPage shows the API documentation page
func (h *Handlers) DocsPage(c echo.Context) error {
	data := map[string]interface{}{
		"Title":    "API Documentation | willow.camp",
		"Themes":   allThemes,
		"Emojis":   emojiOptions,
		"ShowLogo": true, // Show logo in navbar on docs page
	}

	return renderApplicationTemplate(c, "docs.html", data)
}
