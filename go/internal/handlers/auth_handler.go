package handlers

import (
	"net/http"

	"github.com/cassiascheffer/willow_camp/internal/auth"
	"github.com/labstack/echo/v4"
)

// LoginPage shows the login form
func (h *Handlers) LoginPage(c echo.Context) error {
	data := map[string]interface{}{
		"Title": "Login",
		"Error": c.QueryParam("error"),
	}

	return renderAuthTemplate(c, "login.html", data)
}

// LoginSubmit handles login form submission
func (h *Handlers) LoginSubmit(c echo.Context) error {
	email := c.FormValue("email")
	password := c.FormValue("password")

	user, err := h.auth.Login(c, email, password)
	if err != nil {
		if err == auth.ErrInvalidCredentials {
			return c.Redirect(http.StatusFound, "/login?error=invalid")
		}
		return echo.NewHTTPError(http.StatusInternalServerError, "Login failed")
	}

	// Successful login - redirect to dashboard
	_ = user // We don't need the user here, it's in the session
	return c.Redirect(http.StatusFound, "/dashboard")
}

// Logout handles logout
func (h *Handlers) Logout(c echo.Context) error {
	if err := h.auth.Logout(c); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Logout failed")
	}

	return c.Redirect(http.StatusFound, "/")
}

// renderAuthTemplate renders templates without blog context (for auth pages)
func renderAuthTemplate(c echo.Context, templateName string, data interface{}) error {
	return renderSimpleTemplate(c, templateName, data)
}
