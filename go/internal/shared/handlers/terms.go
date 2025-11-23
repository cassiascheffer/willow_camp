package handlers

import (
	"github.com/labstack/echo/v4"
)

// TermsPage shows the Terms of Service page
func (h *Handlers) TermsPage(c echo.Context) error {
	data := map[string]interface{}{
		"Title":    "Terms of Service - willow.camp",
		"ShowLogo": true,
	}

	return renderApplicationTemplate(c, "terms.html", data)
}
