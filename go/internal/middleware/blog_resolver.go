package middleware

import (
	"errors"
	"net/http"
	"strings"

	"github.com/cassiascheffer/willow_camp/internal/models"
	"github.com/cassiascheffer/willow_camp/internal/repository"
	"github.com/labstack/echo/v4"
)

const blogContextKey = "blog"

// BlogResolver middleware resolves the blog from the request hostname
func BlogResolver(blogRepo *repository.BlogRepository) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			host := c.Request().Host

			// Strip port if present
			if idx := strings.Index(host, ":"); idx != -1 {
				host = host[:idx]
			}

			// Extract subdomain or use full domain for custom domain lookup
			domain := extractDomain(host)

			// Look up blog by subdomain or custom domain
			blog, err := blogRepo.FindByDomain(c.Request().Context(), domain)
			if err != nil {
				if errors.Is(err, repository.ErrBlogNotFound) {
					return echo.NewHTTPError(http.StatusNotFound, "Blog not found")
				}
				return echo.NewHTTPError(http.StatusInternalServerError, "Failed to resolve blog")
			}

			// Store blog in context
			c.Set(blogContextKey, blog)

			return next(c)
		}
	}
}

// GetBlog retrieves the blog from the Echo context
func GetBlog(c echo.Context) *models.Blog {
	blog, ok := c.Get(blogContextKey).(*models.Blog)
	if !ok {
		return nil
	}
	return blog
}

// extractDomain extracts the subdomain or returns the full domain for custom domain lookup
// For willow.camp domains: extracts subdomain (e.g., "myblog" from "myblog.willow.camp")
// For custom domains: returns full domain (e.g., "example.com")
func extractDomain(host string) string {
	// Check if it's a willow.camp subdomain
	if strings.HasSuffix(host, ".willow.camp") {
		// Extract subdomain
		subdomain := strings.TrimSuffix(host, ".willow.camp")
		// Handle nested subdomains (take the first part only)
		if idx := strings.Index(subdomain, "."); idx != -1 {
			return subdomain[:idx]
		}
		return subdomain
	}

	// For custom domains, return the full host
	return host
}
