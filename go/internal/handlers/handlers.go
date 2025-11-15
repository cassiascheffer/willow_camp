package handlers

import (
	"github.com/cassiascheffer/willow_camp/internal/repository"
)

// Handlers holds all handler instances and their dependencies
type Handlers struct {
	repos *repository.Repositories
}

// New creates a new Handlers instance
func New(repos *repository.Repositories) *Handlers {
	return &Handlers{
		repos: repos,
	}
}
