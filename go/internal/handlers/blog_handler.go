package handlers

import (
	"net/http"

	"github.com/cassiascheffer/willow_camp/internal/middleware"
	"github.com/labstack/echo/v4"
)

// BlogIndex shows the blog's published posts
func (h *Handlers) BlogIndex(c echo.Context) error {
	blog := middleware.GetBlog(c)
	if blog == nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Blog not found in context")
	}

	// TODO: Implement in next commit
	return c.String(http.StatusOK, "Blog Index - "+*blog.Title)
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
