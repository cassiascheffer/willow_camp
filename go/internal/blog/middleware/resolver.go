package middleware

import (
	"errors"
	"net/http"
	"strings"

	"github.com/cassiascheffer/willow_camp/internal/logging"
	"github.com/cassiascheffer/willow_camp/internal/models"
	"github.com/cassiascheffer/willow_camp/internal/repository"
	"github.com/labstack/echo/v4"
	"github.com/weppos/publicsuffix-go/publicsuffix"
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

			// Skip blog resolution for root willow.camp domain (no subdomain)
			// These requests will proceed without a blog in context (for landing page)
			if host == "willow.camp" || host == "localhost" {
				return next(c)
			}

			// Extract subdomain or use full domain for custom domain lookup
			domain := extractDomain(host)

			// Look up blog by subdomain or custom domain
			blog, err := blogRepo.FindByDomain(c.Request().Context(), domain)
			if err != nil {
				// Get logger from context
				logger := getLogger(c)

				if errors.Is(err, repository.ErrBlogNotFound) {
					logger.Warn("Blog not found", "domain", domain, "host", host)
					return echo.NewHTTPError(http.StatusNotFound, "Blog not found")
				}

				logger.Error("Failed to resolve blog", "domain", domain, "host", host, "error", err)
				return echo.NewHTTPError(http.StatusInternalServerError, "Failed to resolve blog")
			}

			// Store blog in context
			c.Set(blogContextKey, blog)

			return next(c)
		}
	}
}

// getLogger retrieves the logger from the Echo context
func getLogger(c echo.Context) *logging.Logger {
	if logger, ok := c.Get("logger").(*logging.Logger); ok {
		return logger
	}
	// Fallback to a new logger if not found in context
	return logging.NewLogger()
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
// For localhost development: extracts subdomain (e.g., "myblog" from "myblog.localhost")
// For custom domains: returns full domain (e.g., "example.com")
// Uses publicsuffix package for accurate subdomain identification
func extractDomain(host string) string {
	// Handle localhost development specially (not a valid public suffix)
	if strings.HasSuffix(host, ".localhost") {
		// Extract subdomain
		subdomain := strings.TrimSuffix(host, ".localhost")
		// Handle nested subdomains (take the first part only)
		if idx := strings.Index(subdomain, "."); idx != -1 {
			return subdomain[:idx]
		}
		return subdomain
	}

	// Parse the domain using publicsuffix
	domainName, err := publicsuffix.Parse(host)
	if err != nil {
		// If we can't parse the domain, return the full host
		// This handles edge cases like IP addresses or malformed domains
		return host
	}

	// Get the registrable domain (eTLD+1)
	// For "myblog.willow.camp", this returns "willow.camp"
	// For "example.com", this returns "example.com"
	// For "blog.example.co.uk", this returns "example.co.uk"
	registrableDomain := domainName.SLD + "." + domainName.TLD

	// Check if this is a willow.camp subdomain
	if registrableDomain == "willow.camp" {
		// Check if there's a subdomain
		if domainName.TRD != "" {
			// Return only the first part of the subdomain
			// e.g., "www.myblog" -> "www"
			parts := strings.Split(domainName.TRD, ".")
			return parts[0]
		}
		// No subdomain, return empty (this shouldn't happen in normal flow)
		return ""
	}

	// For custom domains, return the full host
	// This handles both apex domains (example.com) and subdomains (blog.example.com)
	return host
}
