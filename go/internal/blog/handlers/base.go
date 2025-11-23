package handlers

import (
	"html/template"
	"net/http"

	"github.com/cassiascheffer/willow_camp/internal/auth"
	"github.com/cassiascheffer/willow_camp/internal/blog/middleware"
	"github.com/cassiascheffer/willow_camp/internal/helpers"
	"github.com/cassiascheffer/willow_camp/internal/logging"
	"github.com/cassiascheffer/willow_camp/internal/models"
	"github.com/cassiascheffer/willow_camp/internal/repository"
	"github.com/labstack/echo/v4"
)

const postsPerPage = 50

// Handlers holds blog handler dependencies
type Handlers struct {
	repos       *repository.Repositories
	auth        *auth.Auth
	baseDomain  string
	homeHandler func(c echo.Context) error
}

// New creates a new blog Handlers instance
func New(repos *repository.Repositories, authService *auth.Auth, baseDomain string) *Handlers {
	return &Handlers{
		repos:      repos,
		auth:       authService,
		baseDomain: baseDomain,
	}
}

// SetHomeHandler sets the home page handler function
func (h *Handlers) SetHomeHandler(handler func(c echo.Context) error) {
	h.homeHandler = handler
}

// getLogger retrieves the logger from the Echo context
func getLogger(c echo.Context) *logging.Logger {
	if logger, ok := c.Get("logger").(*logging.Logger); ok {
		return logger
	}
	// Fallback to a new logger if not found in context
	return logging.NewLogger()
}

// getTitle returns the blog title for display
func getTitle(blog *models.Blog) string {
	if blog.Title != nil && *blog.Title != "" {
		return *blog.Title
	}
	if blog.Subdomain != nil && *blog.Subdomain != "" {
		return *blog.Subdomain
	}
	if blog.CustomDomain != nil && *blog.CustomDomain != "" {
		return *blog.CustomDomain
	}
	return "willow.camp"
}

// enrichTemplateData adds layout requirements to template data
func (h *Handlers) enrichTemplateData(c echo.Context, blog *models.Blog, data map[string]interface{}) map[string]interface{} {
	// Ensure we have all required fields for the layout
	if _, exists := data["Title"]; !exists {
		data["Title"] = getTitle(blog)
	}

	// Blog title for display
	data["BlogTitle"] = getTitle(blog)

	// OpenMoji favicon filename
	emojiFilename := "1F3D5" // Default camping emoji
	if blog.FaviconEmoji != nil && *blog.FaviconEmoji != "" {
		emojiFilename = helpers.EmojiToOpenmojiFilename(*blog.FaviconEmoji)
	}
	data["EmojiFilename"] = emojiFilename

	// Fetch published pages for navigation
	pages, err := h.repos.Post.ListPublishedPages(c.Request().Context(), blog.ID)
	if err != nil {
		// Don't fail the whole page if pages fail to load
		logger := getLogger(c)
		logger.Warn("Failed to load pages for navigation", "blog_id", blog.ID, "error", err)
		pages = []*models.Post{}
	}
	data["Pages"] = pages

	// Open Graph defaults
	if _, exists := data["OGTitle"]; !exists {
		data["OGTitle"] = data["Title"]
	}
	if _, exists := data["OGDescription"]; !exists {
		if blog.MetaDescription != nil && *blog.MetaDescription != "" {
			data["OGDescription"] = *blog.MetaDescription
		} else {
			data["OGDescription"] = "A blog powered by willow.camp"
		}
	}
	if _, exists := data["OGType"]; !exists {
		data["OGType"] = "website"
	}

	// Current URL for Open Graph
	scheme := "http"
	if c.Request().TLS != nil || c.Request().Header.Get("X-Forwarded-Proto") == "https" {
		scheme = "https"
	}
	data["CurrentURL"] = scheme + "://" + c.Request().Host + c.Request().URL.String()

	return data
}

// renderTemplate renders a blog template with layout
func (h *Handlers) renderTemplate(c echo.Context, templateName string, data interface{}) error {
	logger := getLogger(c)

	// Convert data to map and enrich with layout requirements
	blog := middleware.GetBlog(c)
	dataMap, ok := data.(map[string]interface{})
	if !ok {
		dataMap = map[string]interface{}{"Data": data}
	}

	if blog != nil {
		dataMap = h.enrichTemplateData(c, blog, dataMap)
	}

	// Create template with helper functions
	tmpl := template.New("layout.html").Funcs(template.FuncMap{
		"add": func(a, b int) int { return a + b },
		"sub": func(a, b int) int { return a - b },
	})

	// Parse layout and content templates
	tmpl, err := tmpl.ParseFiles(
		"internal/blog/templates/layout.html",
		"internal/blog/templates/"+templateName,
	)
	if err != nil {
		logger.Error("Failed to parse template", "template", templateName, "error", err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Template error: "+err.Error())
	}

	c.Response().Header().Set("Content-Type", "text/html; charset=utf-8")
	c.Response().WriteHeader(http.StatusOK)

	return tmpl.Execute(c.Response().Writer, dataMap)
}
