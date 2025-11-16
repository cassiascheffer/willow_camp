package handlers

import (
	"net/http"

	"github.com/cassiascheffer/willow_camp/internal/auth"
	"github.com/labstack/echo/v4"
	"golang.org/x/crypto/bcrypt"
)

// BlogSettings shows the blog settings form
func (h *Handlers) BlogSettings(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	blogID, err := parseUUID(c.Param("blog_id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid blog ID")
	}

	blog, err := h.repos.Blog.FindByID(c.Request().Context(), blogID)
	if err != nil || blog.UserID != user.ID {
		return echo.NewHTTPError(http.StatusForbidden, "Access denied")
	}

	// Load or create About page
	aboutPage, err := h.repos.Post.FindOrCreateAboutPage(c.Request().Context(), blogID, user.ID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load about page: "+err.Error())
	}

	// Use prepareDashboardData to set NavTitle, NavPath, etc.
	dashData, err := h.prepareDashboardData(user, blog, "Settings - "+getTitle(blog))
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to prepare dashboard data")
	}

	// Convert to map and add AboutPage
	data := map[string]interface{}{
		"Title":         dashData.Title,
		"User":          dashData.User,
		"Blog":          dashData.Blog,
		"NavTitle":      dashData.NavTitle,
		"NavPath":       dashData.NavPath,
		"EmojiFilename": dashData.EmojiFilename,
		"AboutPage":     aboutPage,
	}

	return renderDashboardTemplate(c, "blog_settings.html", data)
}

// UpdateBlogSettings handles blog settings updates
func (h *Handlers) UpdateBlogSettings(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	blogID, err := parseUUID(c.Param("blog_id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid blog ID")
	}

	blog, err := h.repos.Blog.FindByID(c.Request().Context(), blogID)
	if err != nil || blog.UserID != user.ID {
		return echo.NewHTTPError(http.StatusForbidden, "Access denied")
	}

	// Get form data
	blog.Title = stringPtr(c.FormValue("title"))
	blog.Subdomain = stringPtr(c.FormValue("subdomain"))
	blog.CustomDomain = stringPtr(c.FormValue("custom_domain"))
	blog.Theme = c.FormValue("theme")
	blog.PostFooterMarkdown = stringPtr(c.FormValue("post_footer_markdown"))
	blog.MetaDescription = stringPtr(c.FormValue("meta_description"))
	blog.FaviconEmoji = stringPtr(c.FormValue("favicon_emoji"))
	blog.NoIndex = c.FormValue("no_index") == "on"

	if err := h.repos.Blog.Update(c.Request().Context(), blog); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to update blog settings")
	}

	return c.Redirect(http.StatusFound, "/dashboard/blogs/"+blogID.String()+"/settings")
}

// UpdateAboutPage handles About page updates
func (h *Handlers) UpdateAboutPage(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	blogID, err := parseUUID(c.Param("blog_id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid blog ID")
	}

	blog, err := h.repos.Blog.FindByID(c.Request().Context(), blogID)
	if err != nil || blog.UserID != user.ID {
		return echo.NewHTTPError(http.StatusForbidden, "Access denied")
	}

	// Find the About page
	aboutPage, err := h.repos.Post.FindBySlug(c.Request().Context(), blogID, "about")
	if err != nil {
		return echo.NewHTTPError(http.StatusNotFound, "About page not found")
	}

	// Update About page fields
	aboutPage.BodyMarkdown = stringPtr(c.FormValue("body_markdown"))
	published := c.FormValue("published") == "on"
	aboutPage.Published = &published

	if err := h.repos.Post.Update(c.Request().Context(), aboutPage); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to update about page")
	}

	return c.Redirect(http.StatusFound, "/dashboard/blogs/"+blogID.String()+"/settings")
}

// DeleteAboutPage handles About page deletion
func (h *Handlers) DeleteAboutPage(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	blogID, err := parseUUID(c.Param("blog_id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid blog ID")
	}

	blog, err := h.repos.Blog.FindByID(c.Request().Context(), blogID)
	if err != nil || blog.UserID != user.ID {
		return echo.NewHTTPError(http.StatusForbidden, "Access denied")
	}

	// Find the About page
	aboutPage, err := h.repos.Post.FindBySlug(c.Request().Context(), blogID, "about")
	if err != nil {
		return echo.NewHTTPError(http.StatusNotFound, "About page not found")
	}

	if err := h.repos.Post.Delete(c.Request().Context(), aboutPage.ID); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to delete about page")
	}

	return c.Redirect(http.StatusFound, "/dashboard/blogs/"+blogID.String()+"/settings")
}

// DeleteBlog handles blog deletion
func (h *Handlers) DeleteBlog(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	blogID, err := parseUUID(c.Param("blog_id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid blog ID")
	}

	blog, err := h.repos.Blog.FindByID(c.Request().Context(), blogID)
	if err != nil || blog.UserID != user.ID {
		return echo.NewHTTPError(http.StatusForbidden, "Access denied")
	}

	if err := h.repos.Blog.Delete(c.Request().Context(), blogID); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to delete blog")
	}

	// Redirect to dashboard home
	return c.Redirect(http.StatusFound, "/dashboard")
}

// UserSettings shows the user settings form
func (h *Handlers) UserSettings(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	data := map[string]interface{}{
		"Title": "Account Settings",
		"User":  user,
	}

	return renderDashboardTemplate(c, "user_settings.html", data)
}

// UpdateUserSettings handles user profile updates
func (h *Handlers) UpdateUserSettings(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	// Get form data
	name := c.FormValue("name")
	email := c.FormValue("email")

	user.Name = stringPtr(name)
	user.Email = email

	if err := h.repos.User.Update(c.Request().Context(), user); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to update settings")
	}

	return c.Redirect(http.StatusFound, "/dashboard/settings")
}

// UpdatePassword handles password changes
func (h *Handlers) UpdatePassword(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	currentPassword := c.FormValue("current_password")
	newPassword := c.FormValue("new_password")
	confirmPassword := c.FormValue("confirm_password")

	// Verify current password
	if err := bcrypt.CompareHashAndPassword([]byte(user.EncryptedPassword), []byte(currentPassword)); err != nil {
		return c.Redirect(http.StatusFound, "/dashboard/settings?error=invalid_password")
	}

	// Verify new passwords match
	if newPassword != confirmPassword {
		return c.Redirect(http.StatusFound, "/dashboard/settings?error=password_mismatch")
	}

	// Hash new password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to hash password")
	}

	user.EncryptedPassword = string(hashedPassword)

	if err := h.repos.User.Update(c.Request().Context(), user); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to update password")
	}

	return c.Redirect(http.StatusFound, "/dashboard/settings?success=password_updated")
}
