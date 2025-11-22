package repository

import (
	"github.com/jackc/pgx/v5/pgxpool"
)

// Repositories holds all repository instances
type Repositories struct {
	Blog  *BlogRepository
	Post  *PostRepository
	User  *UserRepository
	Tag   *TagRepository
	Token *TokenRepository
}

// NewRepositories creates a new Repositories instance
func NewRepositories(pool *pgxpool.Pool) *Repositories {
	return &Repositories{
		Blog:  NewBlogRepository(pool),
		Post:  NewPostRepository(pool),
		User:  NewUserRepository(pool),
		Tag:   NewTagRepository(pool),
		Token: NewTokenRepository(pool),
	}
}
