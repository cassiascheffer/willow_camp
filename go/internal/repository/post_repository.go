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

var ErrPostNotFound = errors.New("post not found")

type PostRepository struct {
	pool *pgxpool.Pool
}

func NewPostRepository(pool *pgxpool.Pool) *PostRepository {
	return &PostRepository{pool: pool}
}

// FindBySlug finds a post by slug within a blog
func (r *PostRepository) FindBySlug(ctx context.Context, blogID uuid.UUID, slug string) (*models.Post, error) {
	query := `
		SELECT id, blog_id, author_id, title, slug, body_markdown, meta_description,
		       published, published_at, type, has_mermaid_diagrams, featured,
		       created_at, updated_at
		FROM posts
		WHERE blog_id = $1 AND slug = $2
		LIMIT 1
	`

	var post models.Post
	err := r.pool.QueryRow(ctx, query, blogID, slug).Scan(
		&post.ID, &post.BlogID, &post.AuthorID, &post.Title, &post.Slug,
		&post.BodyMarkdown, &post.MetaDescription, &post.Published, &post.PublishedAt,
		&post.Type, &post.HasMermaidDiagrams, &post.Featured,
		&post.CreatedAt, &post.UpdatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrPostNotFound
		}
		return nil, fmt.Errorf("failed to find post: %w", err)
	}

	return &post, nil
}

// FindByID finds a post by ID
func (r *PostRepository) FindByID(ctx context.Context, id uuid.UUID) (*models.Post, error) {
	query := `
		SELECT id, blog_id, author_id, title, slug, body_markdown, meta_description,
		       published, published_at, type, has_mermaid_diagrams, featured,
		       created_at, updated_at
		FROM posts
		WHERE id = $1
	`

	var post models.Post
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&post.ID, &post.BlogID, &post.AuthorID, &post.Title, &post.Slug,
		&post.BodyMarkdown, &post.MetaDescription, &post.Published, &post.PublishedAt,
		&post.Type, &post.HasMermaidDiagrams, &post.Featured,
		&post.CreatedAt, &post.UpdatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrPostNotFound
		}
		return nil, fmt.Errorf("failed to find post: %w", err)
	}

	return &post, nil
}

// ListPublished lists published posts for a blog with pagination
func (r *PostRepository) ListPublished(ctx context.Context, blogID uuid.UUID, limit, offset int) ([]*models.Post, error) {
	query := `
		SELECT id, blog_id, author_id, title, slug, body_markdown, meta_description,
		       published, published_at, type, has_mermaid_diagrams, featured,
		       created_at, updated_at
		FROM posts
		WHERE blog_id = $1 AND published = true AND (type IS NULL OR type = 'Post')
		ORDER BY published_at DESC NULLS LAST, created_at DESC
		LIMIT $2 OFFSET $3
	`

	rows, err := r.pool.Query(ctx, query, blogID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to query posts: %w", err)
	}
	defer rows.Close()

	return r.scanPosts(rows)
}

// ListFeatured lists featured published posts for a blog
func (r *PostRepository) ListFeatured(ctx context.Context, blogID uuid.UUID, limit int) ([]*models.Post, error) {
	query := `
		SELECT id, blog_id, author_id, title, slug, body_markdown, meta_description,
		       published, published_at, type, has_mermaid_diagrams, featured,
		       created_at, updated_at
		FROM posts
		WHERE blog_id = $1 AND published = true AND featured = true AND (type IS NULL OR type = 'Post')
		ORDER BY published_at DESC NULLS LAST, created_at DESC
		LIMIT $2
	`

	rows, err := r.pool.Query(ctx, query, blogID, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to query featured posts: %w", err)
	}
	defer rows.Close()

	return r.scanPosts(rows)
}

// ListAll lists all posts for a blog (including drafts) with pagination
func (r *PostRepository) ListAll(ctx context.Context, blogID uuid.UUID, limit, offset int) ([]*models.Post, error) {
	query := `
		SELECT id, blog_id, author_id, title, slug, body_markdown, meta_description,
		       published, published_at, type, has_mermaid_diagrams, featured,
		       created_at, updated_at
		FROM posts
		WHERE blog_id = $1
		ORDER BY updated_at DESC
		LIMIT $2 OFFSET $3
	`

	rows, err := r.pool.Query(ctx, query, blogID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to query posts: %w", err)
	}
	defer rows.Close()

	return r.scanPosts(rows)
}

// CountPublished counts published posts for a blog
func (r *PostRepository) CountPublished(ctx context.Context, blogID uuid.UUID) (int, error) {
	query := `
		SELECT COUNT(*)
		FROM posts
		WHERE blog_id = $1 AND published = true AND (type IS NULL OR type = 'Post')
	`

	var count int
	err := r.pool.QueryRow(ctx, query, blogID).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("failed to count posts: %w", err)
	}

	return count, nil
}

// Create creates a new post
func (r *PostRepository) Create(ctx context.Context, post *models.Post) error {
	query := `
		INSERT INTO posts (id, blog_id, author_id, title, slug, body_markdown, meta_description,
		                   published, published_at, type, has_mermaid_diagrams, featured,
		                   created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, NOW(), NOW())
	`

	if post.ID == uuid.Nil {
		post.ID = uuid.New()
	}

	_, err := r.pool.Exec(ctx, query,
		post.ID, post.BlogID, post.AuthorID, post.Title, post.Slug, post.BodyMarkdown,
		post.MetaDescription, post.Published, post.PublishedAt, post.Type,
		post.HasMermaidDiagrams, post.Featured,
	)

	if err != nil {
		return fmt.Errorf("failed to create post: %w", err)
	}

	return nil
}

// Update updates a post
func (r *PostRepository) Update(ctx context.Context, post *models.Post) error {
	query := `
		UPDATE posts
		SET title = $2, slug = $3, body_markdown = $4, meta_description = $5,
		    published = $6, published_at = $7, type = $8, has_mermaid_diagrams = $9,
		    featured = $10, updated_at = NOW()
		WHERE id = $1
	`

	_, err := r.pool.Exec(ctx, query,
		post.ID, post.Title, post.Slug, post.BodyMarkdown, post.MetaDescription,
		post.Published, post.PublishedAt, post.Type, post.HasMermaidDiagrams, post.Featured,
	)

	if err != nil {
		return fmt.Errorf("failed to update post: %w", err)
	}

	return nil
}

// Delete deletes a post
func (r *PostRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM posts WHERE id = $1`

	_, err := r.pool.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete post: %w", err)
	}

	return nil
}

// scanPosts is a helper to scan multiple post rows
func (r *PostRepository) scanPosts(rows pgx.Rows) ([]*models.Post, error) {
	var posts []*models.Post

	for rows.Next() {
		var post models.Post
		err := rows.Scan(
			&post.ID, &post.BlogID, &post.AuthorID, &post.Title, &post.Slug,
			&post.BodyMarkdown, &post.MetaDescription, &post.Published, &post.PublishedAt,
			&post.Type, &post.HasMermaidDiagrams, &post.Featured,
			&post.CreatedAt, &post.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan post: %w", err)
		}
		posts = append(posts, &post)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating posts: %w", err)
	}

	return posts, nil
}
