package handlers

import (
	"github.com/cassiascheffer/willow_camp/internal/auth"
	"github.com/cassiascheffer/willow_camp/internal/logging"
	"github.com/cassiascheffer/willow_camp/internal/repository"
	"github.com/labstack/echo/v4"
)

// Handlers holds all handler instances and their dependencies
type Handlers struct {
	repos      *repository.Repositories
	auth       *auth.Auth
	baseDomain string
}

// New creates a new Handlers instance
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
