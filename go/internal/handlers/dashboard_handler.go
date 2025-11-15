package handlers

import (
	"html/template"
	"net/http"

	"github.com/cassiascheffer/willow_camp/internal/auth"
	"github.com/labstack/echo/v4"
)

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
