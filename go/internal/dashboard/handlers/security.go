package handlers

import (
	"net/http"
	"regexp"
	"time"

	"github.com/cassiascheffer/willow_camp/internal/auth"
	"github.com/cassiascheffer/willow_camp/internal/models"
	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"golang.org/x/crypto/bcrypt"
)

// Security shows the security settings page
func (h *Handlers) Security(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	// Get user's blogs for navigation dropdown
	blogs, err := h.repos.Blog.FindByUserID(c.Request().Context(), user.ID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load blogs")
	}

	// Set blogs on user for navigation dropdown
	user.Blogs = blogs

	// Determine the last viewed blog from Referer header or default to primary/first blog
	var lastViewedBlog *models.Blog
	referer := c.Request().Referer()
	if referer != "" {
		// Try to extract subdomain from referer (e.g., /dashboard/blogs/{subdomain}/...)
		re := regexp.MustCompile(`/dashboard/blogs/([^/]+)`)
		matches := re.FindStringSubmatch(referer)
		if len(matches) > 1 {
			subdomain := matches[1]
			// Find the blog with this subdomain
			for _, b := range blogs {
				if b.Subdomain != nil && *b.Subdomain == subdomain {
					lastViewedBlog = b
					break
				}
			}
		}
	}

	// If no blog found from referer, use primary or first blog
	if lastViewedBlog == nil {
		for _, b := range blogs {
			if b.Primary {
				lastViewedBlog = b
				break
			}
		}
		if lastViewedBlog == nil && len(blogs) > 0 {
			lastViewedBlog = blogs[0]
		}
	}

	// Use prepareDashboardData without a blog (global page)
	dashData, err := h.prepareDashboardData(user, nil, "Security Settings")
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to prepare dashboard data")
	}

	// Get success/error messages from query params
	successMsg := c.QueryParam("success")
	errorMsg := c.QueryParam("error")

	// Build template data
	data := map[string]interface{}{
		"Title":          dashData.Title,
		"User":           dashData.User,
		"NavTitle":       dashData.NavTitle,
		"NavPath":        dashData.NavPath,
		"BaseDomain":     dashData.BaseDomain,
		"EmojiFilename":  dashData.EmojiFilename,
		"LastViewedBlog": lastViewedBlog,
		"SuccessMessage": successMsg,
		"ErrorMessage":   errorMsg,
	}

	return renderDashboardTemplate(c, "security.html", data)
}

// GetTokens returns user's API tokens as JSON
func (h *Handlers) GetTokens(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	tokens, err := h.repos.Token.FindByUserID(c.Request().Context(), user.ID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load tokens")
	}

	return c.JSON(http.StatusOK, tokens)
}

// UpdateProfile handles profile updates from the security page
func (h *Handlers) UpdateProfile(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	// Get form data
	name := c.FormValue("name")
	email := c.FormValue("email")
	currentPassword := c.FormValue("current_password")
	newPassword := c.FormValue("new_password")
	confirmPassword := c.FormValue("confirm_password")

	// Validate email
	if email == "" {
		if c.Request().Header.Get("Accept") == "application/json" {
			return c.JSON(http.StatusBadRequest, map[string]interface{}{
				"success": false,
				"message": "Email is required",
			})
		}
		return c.Redirect(http.StatusFound, "/dashboard/security?error=email_required")
	}

	// Verify current password (required for any update)
	if err := bcrypt.CompareHashAndPassword([]byte(user.EncryptedPassword), []byte(currentPassword)); err != nil {
		if c.Request().Header.Get("Accept") == "application/json" {
			return c.JSON(http.StatusBadRequest, map[string]interface{}{
				"success": false,
				"message": "Current password is incorrect",
			})
		}
		return c.Redirect(http.StatusFound, "/dashboard/security?error=invalid_password")
	}

	// Update user fields
	if name != "" {
		user.Name = &name
	} else {
		user.Name = nil
	}
	user.Email = email

	// If new password is provided, update it
	if newPassword != "" {
		// Verify new passwords match
		if newPassword != confirmPassword {
			if c.Request().Header.Get("Accept") == "application/json" {
				return c.JSON(http.StatusBadRequest, map[string]interface{}{
					"success": false,
					"message": "New passwords do not match",
				})
			}
			return c.Redirect(http.StatusFound, "/dashboard/security?error=password_mismatch")
		}

		// Hash new password
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
		if err != nil {
			if c.Request().Header.Get("Accept") == "application/json" {
				return c.JSON(http.StatusInternalServerError, map[string]interface{}{
					"success": false,
					"message": "Failed to hash password",
				})
			}
			return echo.NewHTTPError(http.StatusInternalServerError, "Failed to hash password")
		}

		user.EncryptedPassword = string(hashedPassword)
	}

	if err := h.repos.User.Update(c.Request().Context(), user); err != nil {
		if c.Request().Header.Get("Accept") == "application/json" {
			return c.JSON(http.StatusInternalServerError, map[string]interface{}{
				"success": false,
				"message": "Failed to update profile",
			})
		}
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to update profile")
	}

	// Determine success message based on whether password was changed
	var successMessage string
	if newPassword != "" {
		successMessage = "Profile and password updated successfully"
	} else {
		successMessage = "Profile updated successfully"
	}

	// For AJAX requests, return success
	if c.Request().Header.Get("Accept") == "application/json" {
		return c.JSON(http.StatusOK, map[string]interface{}{
			"success": true,
			"message": successMessage,
		})
	}

	return c.Redirect(http.StatusFound, "/dashboard/security?success=profile_updated")
}

// UpdateSecurityPassword handles password changes with current password verification
func (h *Handlers) UpdateSecurityPassword(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	currentPassword := c.FormValue("current_password")
	newPassword := c.FormValue("new_password")
	confirmPassword := c.FormValue("confirm_password")

	// Verify current password
	if err := bcrypt.CompareHashAndPassword([]byte(user.EncryptedPassword), []byte(currentPassword)); err != nil {
		if c.Request().Header.Get("Accept") == "application/json" {
			return c.JSON(http.StatusBadRequest, map[string]interface{}{
				"success": false,
				"message": "Current password is incorrect",
			})
		}
		return c.Redirect(http.StatusFound, "/dashboard/security?error=invalid_password")
	}

	// Verify new passwords match
	if newPassword != confirmPassword {
		if c.Request().Header.Get("Accept") == "application/json" {
			return c.JSON(http.StatusBadRequest, map[string]interface{}{
				"success": false,
				"message": "New passwords do not match",
			})
		}
		return c.Redirect(http.StatusFound, "/dashboard/security?error=password_mismatch")
	}

	// Hash new password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		if c.Request().Header.Get("Accept") == "application/json" {
			return c.JSON(http.StatusInternalServerError, map[string]interface{}{
				"success": false,
				"message": "Failed to hash password",
			})
		}
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to hash password")
	}

	user.EncryptedPassword = string(hashedPassword)

	if err := h.repos.User.Update(c.Request().Context(), user); err != nil {
		if c.Request().Header.Get("Accept") == "application/json" {
			return c.JSON(http.StatusInternalServerError, map[string]interface{}{
				"success": false,
				"message": "Failed to update password",
			})
		}
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to update password")
	}

	// For AJAX requests, return success
	if c.Request().Header.Get("Accept") == "application/json" {
		return c.JSON(http.StatusOK, map[string]interface{}{
			"success": true,
			"message": "Password updated successfully",
		})
	}

	return c.Redirect(http.StatusFound, "/dashboard/security?success=password_updated")
}

// CreateToken handles API token creation
func (h *Handlers) CreateToken(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	name := c.FormValue("name")
	if name == "" {
		// Check if this is an AJAX request
		if c.Request().Header.Get("Accept") == "application/json" {
			return c.JSON(http.StatusBadRequest, map[string]interface{}{
				"success": false,
				"message": "Token name is required",
			})
		}
		return c.Redirect(http.StatusFound, "/dashboard/security?error=name_required")
	}

	// Parse expiration date if provided
	var expiresAt *time.Time
	expiresAtStr := c.FormValue("expires_at")
	if expiresAtStr != "" {
		parsedTime, err := time.Parse("2006-01-02", expiresAtStr)
		if err != nil {
			if c.Request().Header.Get("Accept") == "application/json" {
				return c.JSON(http.StatusBadRequest, map[string]interface{}{
					"success": false,
					"message": "Invalid expiration date",
				})
			}
			return c.Redirect(http.StatusFound, "/dashboard/security?error=invalid_date")
		}
		// Check if expiration is in the future
		if !parsedTime.After(time.Now()) {
			if c.Request().Header.Get("Accept") == "application/json" {
				return c.JSON(http.StatusBadRequest, map[string]interface{}{
					"success": false,
					"message": "Expiration date must be in the future",
				})
			}
			return c.Redirect(http.StatusFound, "/dashboard/security?error=expiration_must_be_future")
		}
		expiresAt = &parsedTime
	}

	// Create the token
	newToken, err := h.repos.Token.Create(c.Request().Context(), user.ID, name, expiresAt)
	if err != nil {
		if c.Request().Header.Get("Accept") == "application/json" {
			return c.JSON(http.StatusInternalServerError, map[string]interface{}{
				"success": false,
				"message": "Failed to create token: " + err.Error(),
			})
		}
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to create token: "+err.Error())
	}

	// For AJAX requests, return success with the new token
	if c.Request().Header.Get("Accept") == "application/json" {
		return c.JSON(http.StatusOK, map[string]interface{}{
			"success": true,
			"message": "Token created successfully",
			"token":   newToken,
		})
	}

	return c.Redirect(http.StatusFound, "/dashboard/security?success=token_created")
}

// DeleteToken handles API token deletion
func (h *Handlers) DeleteToken(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	tokenIDParam := c.Param("id")
	tokenID, err := uuid.Parse(tokenIDParam)
	if err != nil {
		if c.Request().Header.Get("Accept") == "application/json" {
			return c.JSON(http.StatusBadRequest, map[string]interface{}{
				"success": false,
				"message": "Invalid token ID",
			})
		}
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid token ID")
	}

	// Delete the token (repository checks ownership)
	err = h.repos.Token.Delete(c.Request().Context(), tokenID, user.ID)
	if err != nil {
		if c.Request().Header.Get("Accept") == "application/json" {
			return c.JSON(http.StatusInternalServerError, map[string]interface{}{
				"success": false,
				"message": "Failed to delete token: " + err.Error(),
			})
		}
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to delete token: "+err.Error())
	}

	// For AJAX requests, return success
	if c.Request().Header.Get("Accept") == "application/json" {
		return c.JSON(http.StatusOK, map[string]interface{}{
			"success": true,
			"message": "Token deleted successfully",
		})
	}

	return c.Redirect(http.StatusFound, "/dashboard/security?success=token_deleted")
}
