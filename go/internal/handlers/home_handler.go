package handlers

import (
	"net/http"

	"github.com/labstack/echo/v4"
)

// HomePage shows the landing page or redirects to dashboard if logged in
func (h *Handlers) HomePage(c echo.Context) error {
	// Check if user is logged in
	user, err := h.auth.GetCurrentUser(c)
	if err == nil && user != nil {
		// User is logged in, redirect to dashboard
		return c.Redirect(http.StatusFound, "/dashboard")
	}

	// User is not logged in, show home page
	data := map[string]interface{}{
		"Title": "willow.camp - A blogging platform",
	}

	return renderSimpleTemplate(c, "home.html", data)
}
