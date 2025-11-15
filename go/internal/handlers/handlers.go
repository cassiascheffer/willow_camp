package handlers

import (
	"github.com/cassiascheffer/willow_camp/internal/auth"
	"github.com/cassiascheffer/willow_camp/internal/repository"
)

// Handlers holds all handler instances and their dependencies
type Handlers struct {
	repos *repository.Repositories
	auth  *auth.Auth
}

// New creates a new Handlers instance
func New(repos *repository.Repositories, authService *auth.Auth) *Handlers {
	return &Handlers{
		repos: repos,
		auth:  authService,
	}
}
