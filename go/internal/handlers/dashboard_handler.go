package handlers

import (
	"html/template"
	"net/http"

	"github.com/cassiascheffer/willow_camp/internal/auth"
	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
)

func parseUUID(s string) (uuid.UUID, error) {
	return uuid.Parse(s)
}

// Dashboard shows the main dashboard
func (h *Handlers) Dashboard(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	// Get user's blogs
	blogs, err := h.repos.Blog.FindByUserID(c.Request().Context(), user.ID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load blogs")
	}

	// If user has only one blog, redirect to that blog's posts
	if len(blogs) == 1 {
		return c.Redirect(http.StatusFound, "/dashboard/blogs/"+blogs[0].ID.String()+"/posts")
	}

	// Show blog selection page
	data := map[string]interface{}{
		"Title": "Dashboard",
		"User":  user,
		"Blogs": blogs,
	}

	return renderDashboardTemplate(c, "dashboard_index.html", data)
}

// BlogPosts shows the post list for a specific blog
func (h *Handlers) BlogPosts(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	blogID, err := parseUUID(c.Param("blog_id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid blog ID")
	}

	// Verify blog belongs to user
	blog, err := h.repos.Blog.FindByID(c.Request().Context(), blogID)
	if err != nil {
		return echo.NewHTTPError(http.StatusNotFound, "Blog not found")
	}
	if blog.UserID != user.ID {
		return echo.NewHTTPError(http.StatusForbidden, "Access denied")
	}

	// Get all posts (including drafts) for this blog
	posts, err := h.repos.Post.ListAll(c.Request().Context(), blogID, 100, 0)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load posts")
	}

	data := map[string]interface{}{
		"Title": "Posts - " + getTitle(blog),
		"User":  user,
		"Blog":  blog,
		"Posts": posts,
	}

	return renderDashboardTemplate(c, "posts_list.html", data)
}

func renderDashboardTemplate(c echo.Context, templateName string, data interface{}) error {
	// Dashboard template rendering
	tmpl := template.New("dashboard_layout.html")

	// Parse dashboard layout and content templates
	tmpl, err := tmpl.ParseFiles(
		"internal/templates/dashboard_layout.html",
		"internal/templates/"+templateName,
	)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Template error: "+err.Error())
	}

	c.Response().Header().Set("Content-Type", "text/html; charset=utf-8")
	c.Response().WriteHeader(http.StatusOK)

	return tmpl.Execute(c.Response().Writer, data)
}
