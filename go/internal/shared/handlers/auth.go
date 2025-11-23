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
	logger := getLogger(c)
	email := c.FormValue("email")
	password := c.FormValue("password")

	user, err := h.auth.Login(c, email, password)
	if err != nil {
		if err == auth.ErrInvalidCredentials {
			logger.Warn("Failed login attempt", "email", email, "ip", c.RealIP(), "error", "invalid credentials")
			return c.Redirect(http.StatusFound, "/login?error=invalid")
		}
		logger.Error("Login failed", "email", email, "ip", c.RealIP(), "error", err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Login failed")
	}

	// Successful login - redirect to dashboard
	logger.Info("Successful login", "user_id", user.ID, "email", email, "ip", c.RealIP())
	return c.Redirect(http.StatusFound, "/dashboard")
}

// Logout handles logout
func (h *Handlers) Logout(c echo.Context) error {
	logger := getLogger(c)

	// Get user ID before logging out (if available from session)
	user, _ := h.auth.GetCurrentUser(c)
	var userID string
	if user != nil {
		userID = user.ID.String()
	}

	if err := h.auth.Logout(c); err != nil {
		logger.Error("Logout failed", "user_id", userID, "error", err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Logout failed")
	}

	logger.Info("User logged out", "user_id", userID, "ip", c.RealIP())
	return c.Redirect(http.StatusFound, "/")
}

// renderAuthTemplate renders templates without blog context (for auth pages)
func renderAuthTemplate(c echo.Context, templateName string, data interface{}) error {
	return renderSimpleTemplate(c, templateName, data)
}
