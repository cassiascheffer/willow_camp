package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/cassiascheffer/willow_camp/internal/auth"
	"github.com/labstack/echo/v4"
)

// BlogSettings shows the blog settings form
func (h *Handlers) BlogSettings(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	// Get blog by subdomain and verify ownership
	blog, err := h.getBlogBySubdomainParam(c, user)
	if err != nil {
		return err
	}

	// Get user's blogs for dropdown
	blogs, err := h.repos.Blog.FindByUserID(c.Request().Context(), user.ID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load blogs")
	}

	// Sort blogs by title for display (matching Rails behavior)
	sortBlogsByTitle(blogs)
	user.Blogs = blogs

	// Load or create About page
	aboutPage, err := h.repos.Post.FindOrCreateAboutPage(c.Request().Context(), blog.ID, user.ID)
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
		"BaseDomain":    dashData.BaseDomain,
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

	// Get blog by subdomain and verify ownership
	blog, err := h.getBlogBySubdomainParam(c, user)
	if err != nil {
		return err
	}

	// Get form data
	updatedSubdomain := c.FormValue("subdomain")
	blog.Title = stringPtr(c.FormValue("title"))
	blog.Subdomain = stringPtr(updatedSubdomain)
	blog.CustomDomain = stringPtr(c.FormValue("custom_domain"))
	blog.Theme = c.FormValue("theme")
	blog.PostFooterMarkdown = stringPtr(c.FormValue("post_footer_markdown"))
	blog.MetaDescription = stringPtr(c.FormValue("meta_description"))
	blog.FaviconEmoji = stringPtr(c.FormValue("favicon_emoji"))
	blog.NoIndex = c.FormValue("no_index") == "on"

	if err := h.repos.Blog.Update(c.Request().Context(), blog); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to update blog settings")
	}

	// Redirect using the updated subdomain
	if updatedSubdomain != "" {
		return c.Redirect(http.StatusFound, "/dashboard/blogs/"+updatedSubdomain+"/settings")
	}
	return echo.NewHTTPError(http.StatusInternalServerError, "Blog subdomain not found")
}

// UpdateFaviconEmoji handles AJAX favicon emoji updates
func (h *Handlers) UpdateFaviconEmoji(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	// Get blog by subdomain and verify ownership
	blog, err := h.getBlogBySubdomainParam(c, user)
	if err != nil {
		return err
	}

	// Parse JSON request body
	var payload struct {
		FaviconEmoji string `json:"favicon_emoji"`
	}
	if err := json.NewDecoder(c.Request().Body).Decode(&payload); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request body")
	}

	// Update only the favicon emoji
	blog.FaviconEmoji = stringPtr(payload.FaviconEmoji)

	if err := h.repos.Blog.Update(c.Request().Context(), blog); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to update favicon")
	}

	// Return JSON response
	return c.JSON(http.StatusOK, map[string]string{
		"status":  "success",
		"message": "Favicon updated successfully",
	})
}

// UpdateAboutPage handles About page updates
func (h *Handlers) UpdateAboutPage(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	// Get blog by subdomain and verify ownership
	blog, err := h.getBlogBySubdomainParam(c, user)
	if err != nil {
		return err
	}

	// Find the About page
	aboutPage, err := h.repos.Post.FindBySlug(c.Request().Context(), blog.ID, "about")
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

	if blog.Subdomain != nil {
		return c.Redirect(http.StatusFound, "/dashboard/blogs/"+*blog.Subdomain+"/settings")
	}
	return echo.NewHTTPError(http.StatusInternalServerError, "Blog subdomain not found")
}

// DeleteAboutPage handles About page deletion
func (h *Handlers) DeleteAboutPage(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	// Get blog by subdomain and verify ownership
	blog, err := h.getBlogBySubdomainParam(c, user)
	if err != nil {
		return err
	}

	// Find the About page
	aboutPage, err := h.repos.Post.FindBySlug(c.Request().Context(), blog.ID, "about")
	if err != nil {
		return echo.NewHTTPError(http.StatusNotFound, "About page not found")
	}

	if err := h.repos.Post.Delete(c.Request().Context(), aboutPage.ID); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to delete about page")
	}

	if blog.Subdomain != nil {
		return c.Redirect(http.StatusFound, "/dashboard/blogs/"+*blog.Subdomain+"/settings")
	}
	return echo.NewHTTPError(http.StatusInternalServerError, "Blog subdomain not found")
}

// DeleteBlog handles blog deletion
func (h *Handlers) DeleteBlog(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	// Get blog by subdomain and verify ownership
	blog, err := h.getBlogBySubdomainParam(c, user)
	if err != nil {
		return err
	}

	if err := h.repos.Blog.Delete(c.Request().Context(), blog.ID); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to delete blog")
	}

	// Redirect to dashboard home
	return c.Redirect(http.StatusFound, "/dashboard")
}

