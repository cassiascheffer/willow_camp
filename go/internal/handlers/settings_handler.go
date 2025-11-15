package handlers

import (
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

	blogID, err := parseUUID(c.Param("blog_id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid blog ID")
	}

	blog, err := h.repos.Blog.FindByID(c.Request().Context(), blogID)
	if err != nil || blog.UserID != user.ID {
		return echo.NewHTTPError(http.StatusForbidden, "Access denied")
	}

	data := map[string]interface{}{
		"Title": "Settings - " + getTitle(blog),
		"User":  user,
		"Blog":  blog,
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
