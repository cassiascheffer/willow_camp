package repository

import (
	"context"
	"errors"
	"fmt"

	"github.com/cassiascheffer/willow_camp/internal/models"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var ErrBlogNotFound = errors.New("blog not found")

type BlogRepository struct {
	pool *pgxpool.Pool
}

func NewBlogRepository(pool *pgxpool.Pool) *BlogRepository {
	return &BlogRepository{pool: pool}
}

// FindByDomain finds a blog by subdomain or custom domain
func (r *BlogRepository) FindByDomain(ctx context.Context, domain string) (*models.Blog, error) {
	query := `
		SELECT id, user_id, subdomain, title, slug, meta_description, favicon_emoji,
		       custom_domain, theme, post_footer_markdown, no_index, "primary",
		       created_at, updated_at
		FROM blogs
		WHERE subdomain = $1 OR custom_domain = $1
		LIMIT 1
	`

	var blog models.Blog
	err := r.pool.QueryRow(ctx, query, domain).Scan(
		&blog.ID, &blog.UserID, &blog.Subdomain, &blog.Title, &blog.Slug,
		&blog.MetaDescription, &blog.FaviconEmoji, &blog.CustomDomain, &blog.Theme,
		&blog.PostFooterMarkdown, &blog.NoIndex, &blog.Primary,
		&blog.CreatedAt, &blog.UpdatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrBlogNotFound
		}
		return nil, fmt.Errorf("failed to find blog by domain: %w", err)
	}

	return &blog, nil
}

// FindBySubdomain finds a blog by its subdomain
func (r *BlogRepository) FindBySubdomain(ctx context.Context, subdomain string) (*models.Blog, error) {
	query := `
		SELECT id, user_id, subdomain, title, slug, meta_description, favicon_emoji,
		       custom_domain, theme, post_footer_markdown, no_index, "primary",
		       created_at, updated_at
		FROM blogs
		WHERE subdomain = $1
		LIMIT 1
	`

	var blog models.Blog
	err := r.pool.QueryRow(ctx, query, subdomain).Scan(
		&blog.ID, &blog.UserID, &blog.Subdomain, &blog.Title, &blog.Slug,
		&blog.MetaDescription, &blog.FaviconEmoji, &blog.CustomDomain, &blog.Theme,
		&blog.PostFooterMarkdown, &blog.NoIndex, &blog.Primary,
		&blog.CreatedAt, &blog.UpdatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrBlogNotFound
		}
		return nil, fmt.Errorf("failed to find blog by subdomain: %w", err)
	}

	return &blog, nil
}

// FindByID finds a blog by its ID
func (r *BlogRepository) FindByID(ctx context.Context, id uuid.UUID) (*models.Blog, error) {
	query := `
		SELECT id, user_id, subdomain, title, slug, meta_description, favicon_emoji,
		       custom_domain, theme, post_footer_markdown, no_index, "primary",
		       created_at, updated_at
		FROM blogs
		WHERE id = $1
	`

	var blog models.Blog
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&blog.ID, &blog.UserID, &blog.Subdomain, &blog.Title, &blog.Slug,
		&blog.MetaDescription, &blog.FaviconEmoji, &blog.CustomDomain, &blog.Theme,
		&blog.PostFooterMarkdown, &blog.NoIndex, &blog.Primary,
		&blog.CreatedAt, &blog.UpdatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrBlogNotFound
		}
		return nil, fmt.Errorf("failed to find blog by ID: %w", err)
	}

	return &blog, nil
}

// FindByUserID finds all blogs for a user
func (r *BlogRepository) FindByUserID(ctx context.Context, userID uuid.UUID) ([]*models.Blog, error) {
	query := `
		SELECT id, user_id, subdomain, title, slug, meta_description, favicon_emoji,
		       custom_domain, theme, post_footer_markdown, no_index, "primary",
		       created_at, updated_at
		FROM blogs
		WHERE user_id = $1
		ORDER BY "primary" DESC, created_at ASC
	`

	rows, err := r.pool.Query(ctx, query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to query blogs: %w", err)
	}
	defer rows.Close()

	var blogs []*models.Blog
	for rows.Next() {
		var blog models.Blog
		err := rows.Scan(
			&blog.ID, &blog.UserID, &blog.Subdomain, &blog.Title, &blog.Slug,
			&blog.MetaDescription, &blog.FaviconEmoji, &blog.CustomDomain, &blog.Theme,
			&blog.PostFooterMarkdown, &blog.NoIndex, &blog.Primary,
			&blog.CreatedAt, &blog.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan blog: %w", err)
		}
		blogs = append(blogs, &blog)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating blogs: %w", err)
	}

	return blogs, nil
}

// Create creates a new blog
func (r *BlogRepository) Create(ctx context.Context, userID uuid.UUID, subdomain string, primary bool) (*models.Blog, error) {
	query := `
		INSERT INTO blogs (user_id, subdomain, "primary", created_at, updated_at)
		VALUES ($1, $2, $3, NOW(), NOW())
		RETURNING id, user_id, subdomain, title, slug, meta_description, favicon_emoji,
		          custom_domain, theme, post_footer_markdown, no_index, "primary",
		          created_at, updated_at
	`

	var blog models.Blog
	err := r.pool.QueryRow(ctx, query, userID, subdomain, primary).Scan(
		&blog.ID, &blog.UserID, &blog.Subdomain, &blog.Title, &blog.Slug,
		&blog.MetaDescription, &blog.FaviconEmoji, &blog.CustomDomain, &blog.Theme,
		&blog.PostFooterMarkdown, &blog.NoIndex, &blog.Primary,
		&blog.CreatedAt, &blog.UpdatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to create blog: %w", err)
	}

	return &blog, nil
}

// Update updates a blog
func (r *BlogRepository) Update(ctx context.Context, blog *models.Blog) error {
	query := `
		UPDATE blogs
		SET subdomain = $2, title = $3, slug = $4, meta_description = $5,
		    favicon_emoji = $6, custom_domain = $7, theme = $8,
		    post_footer_markdown = $9, no_index = $10, updated_at = NOW()
		WHERE id = $1
	`

	_, err := r.pool.Exec(ctx, query,
		blog.ID, blog.Subdomain, blog.Title, blog.Slug, blog.MetaDescription,
		blog.FaviconEmoji, blog.CustomDomain, blog.Theme, blog.PostFooterMarkdown,
		blog.NoIndex,
	)

	if err != nil {
		return fmt.Errorf("failed to update blog: %w", err)
	}

	return nil
}

// Delete deletes a blog and all associated posts/pages
func (r *BlogRepository) Delete(ctx context.Context, id uuid.UUID) error {
	// Note: Posts will be deleted automatically via ON DELETE CASCADE in the database
	query := `DELETE FROM blogs WHERE id = $1`

	_, err := r.pool.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete blog: %w", err)
	}

	return nil
}
