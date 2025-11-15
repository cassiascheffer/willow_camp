package handlers

import (
	"html/template"
	"net/http"
	"strconv"

	"github.com/cassiascheffer/willow_camp/internal/middleware"
	"github.com/cassiascheffer/willow_camp/internal/models"
	"github.com/labstack/echo/v4"
)

const postsPerPage = 10

// BlogIndex shows the blog's published posts
func (h *Handlers) BlogIndex(c echo.Context) error {
	blog := middleware.GetBlog(c)
	if blog == nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Blog not found in context")
	}

	// Get page number from query param
	page := 1
	if pageStr := c.QueryParam("page"); pageStr != "" {
		if p, err := strconv.Atoi(pageStr); err == nil && p > 0 {
			page = p
		}
	}

	// Calculate offset
	offset := (page - 1) * postsPerPage

	// Fetch published posts
	posts, err := h.repos.Post.ListPublished(c.Request().Context(), blog.ID, postsPerPage, offset)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load posts")
	}

	// Get total count for pagination
	totalPosts, err := h.repos.Post.CountPublished(c.Request().Context(), blog.ID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to count posts")
	}

	totalPages := (totalPosts + postsPerPage - 1) / postsPerPage

	// Prepare template data
	data := map[string]interface{}{
		"Blog":        blog,
		"Title":       getTitle(blog),
		"Posts":       posts,
		"CurrentPage": page,
		"TotalPages":  totalPages,
	}

	return renderTemplate(c, "blog_index.html", data)
}

// PostShow shows a single post
func (h *Handlers) PostShow(c echo.Context) error {
	blog := middleware.GetBlog(c)
	if blog == nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Blog not found in context")
	}

	slug := c.Param("slug")

	// TODO: Implement in next commit
	return c.String(http.StatusOK, "Post: "+slug)
}

// Helper functions

func getTitle(blog *models.Blog) string {
	if blog.Title != nil && *blog.Title != "" {
		return *blog.Title
	}
	return "WillowCamp"
}

func renderTemplate(c echo.Context, templateName string, data interface{}) error {
	// Create template with helper functions
	tmpl := template.New("layout.html").Funcs(template.FuncMap{
		"add": func(a, b int) int { return a + b },
		"sub": func(a, b int) int { return a - b },
	})

	// Parse layout and content templates
	tmpl, err := tmpl.ParseFiles(
		"internal/templates/layout.html",
		"internal/templates/"+templateName,
	)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Template error: "+err.Error())
	}

	c.Response().Header().Set("Content-Type", "text/html; charset=utf-8")
	c.Response().WriteHeader(http.StatusOK)

	return tmpl.Execute(c.Response().Writer, data)
}
