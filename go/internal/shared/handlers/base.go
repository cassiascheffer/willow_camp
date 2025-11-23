package handlers

import (
	"html/template"
	"net/http"

	"github.com/cassiascheffer/willow_camp/internal/auth"
	"github.com/cassiascheffer/willow_camp/internal/helpers"
	"github.com/cassiascheffer/willow_camp/internal/logging"
	"github.com/cassiascheffer/willow_camp/internal/repository"
	"github.com/labstack/echo/v4"
)

// Handlers holds shared handler dependencies
type Handlers struct {
	repos      *repository.Repositories
	auth       *auth.Auth
	baseDomain string
}

// New creates a new shared Handlers instance
func New(repos *repository.Repositories, authService *auth.Auth, baseDomain string) *Handlers {
	return &Handlers{
		repos:      repos,
		auth:       authService,
		baseDomain: baseDomain,
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

// templateFuncs returns custom template functions for application templates
func templateFuncs() template.FuncMap {
	return template.FuncMap{
		"heroicon": func(name string, class string) template.HTML {
			return helpers.Icon("24/outline/"+name, class)
		},
		"heroiconMini": func(name string, class string) template.HTML {
			return helpers.Icon("20/solid/"+name, class)
		},
	}
}

// renderSimpleTemplate renders a simple template without blog layout (for auth pages, etc.)
func renderSimpleTemplate(c echo.Context, templateName string, data interface{}) error {
	logger := getLogger(c)

	// Simple template rendering without blog layout (for auth pages, etc.)
	tmpl := template.New("simple_layout.html")

	// Parse simple layout and content templates
	tmpl, err := tmpl.ParseFiles(
		"internal/shared/templates/simple_layout.html",
		"internal/shared/templates/"+templateName,
	)
	if err != nil {
		logger.Error("Failed to parse simple template", "template", templateName, "error", err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Template error: "+err.Error())
	}

	c.Response().Header().Set("Content-Type", "text/html; charset=utf-8")
	c.Response().WriteHeader(http.StatusOK)

	return tmpl.Execute(c.Response().Writer, data)
}

// renderApplicationTemplate renders a template with application layout (navbar, footer, theme/favicon pickers)
func renderApplicationTemplate(c echo.Context, templateName string, data interface{}) error {
	logger := getLogger(c)

	// Application template rendering with custom functions
	tmpl := template.New("application_layout.html").Funcs(templateFuncs())

	// Parse application layout and content templates
	tmpl, err := tmpl.ParseFiles(
		"internal/shared/templates/application_layout.html",
		"internal/shared/templates/"+templateName,
	)
	if err != nil {
		logger.Error("Failed to parse application template", "template", templateName, "error", err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Template error: "+err.Error())
	}

	c.Response().Header().Set("Content-Type", "text/html; charset=utf-8")
	c.Response().WriteHeader(http.StatusOK)

	return tmpl.Execute(c.Response().Writer, data)
}
