package repository

import (
	"context"
	"fmt"

	"github.com/cassiascheffer/willow_camp/internal/models"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type TagRepository struct {
	pool *pgxpool.Pool
}

func NewTagRepository(pool *pgxpool.Pool) *TagRepository {
	return &TagRepository{pool: pool}
}

// FindTagsForPost retrieves all tags for a given post
func (r *TagRepository) FindTagsForPost(ctx context.Context, postID uuid.UUID) ([]models.Tag, error) {
	query := `
		SELECT t.id, t.name, t.slug, t.taggings_count, t.created_at, t.updated_at
		FROM tags t
		INNER JOIN taggings tg ON t.id = tg.tag_id
		WHERE tg.taggable_id = $1 AND tg.taggable_type = 'Post'
		ORDER BY t.name
	`

	rows, err := r.pool.Query(ctx, query, postID)
	if err != nil {
		return nil, fmt.Errorf("failed to query tags: %w", err)
	}
	defer rows.Close()

	var tags []models.Tag
	for rows.Next() {
		var tag models.Tag
		err := rows.Scan(
			&tag.ID, &tag.Name, &tag.Slug, &tag.TaggingsCount,
			&tag.CreatedAt, &tag.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan tag: %w", err)
		}
		tags = append(tags, tag)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating tags: %w", err)
	}

	return tags, nil
}

// ListAllForBlog lists all tags used in a blog (including drafts)
func (r *TagRepository) ListAllForBlog(ctx context.Context, blogID uuid.UUID) ([]string, error) {
	query := `
		SELECT DISTINCT t.name
		FROM tags t
		INNER JOIN taggings tg ON t.id = tg.tag_id
		INNER JOIN posts p ON tg.taggable_id = p.id
		WHERE p.blog_id = $1 AND tg.taggable_type = 'Post'
		ORDER BY t.name
	`

	rows, err := r.pool.Query(ctx, query, blogID)
	if err != nil {
		return nil, fmt.Errorf("failed to query tag names: %w", err)
	}
	defer rows.Close()

	var tagNames []string
	for rows.Next() {
		var name string
		err := rows.Scan(&name)
		if err != nil {
			return nil, fmt.Errorf("failed to scan tag name: %w", err)
		}
		tagNames = append(tagNames, name)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating tag names: %w", err)
	}

	return tagNames, nil
}

// ListForBlog lists all tags used in a blog with post counts (published only)
func (r *TagRepository) ListForBlog(ctx context.Context, blogID uuid.UUID) ([]models.Tag, error) {
	query := `
		SELECT DISTINCT t.id, t.name, t.slug, t.taggings_count, t.created_at, t.updated_at
		FROM tags t
		INNER JOIN taggings tg ON t.id = tg.tag_id
		INNER JOIN posts p ON tg.taggable_id = p.id
		WHERE p.blog_id = $1 AND tg.taggable_type = 'Post' AND p.published = true
		ORDER BY t.taggings_count DESC, t.name
	`

	rows, err := r.pool.Query(ctx, query, blogID)
	if err != nil {
		return nil, fmt.Errorf("failed to query tags: %w", err)
	}
	defer rows.Close()

	var tags []models.Tag
	for rows.Next() {
		var tag models.Tag
		err := rows.Scan(
			&tag.ID, &tag.Name, &tag.Slug, &tag.TaggingsCount,
			&tag.CreatedAt, &tag.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan tag: %w", err)
		}
		tags = append(tags, tag)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating tags: %w", err)
	}

	return tags, nil
}

// FindOrCreateByName finds or creates a tag by name
func (r *TagRepository) FindOrCreateByName(ctx context.Context, name string, slug string) (*models.Tag, error) {
	// Try to find existing tag by name
	query := `SELECT id, name, slug, taggings_count, created_at, updated_at FROM tags WHERE name = $1`
	var tag models.Tag
	err := r.pool.QueryRow(ctx, query, name).Scan(
		&tag.ID, &tag.Name, &tag.Slug, &tag.TaggingsCount,
		&tag.CreatedAt, &tag.UpdatedAt,
	)
	if err == nil {
		return &tag, nil
	}

	// Tag doesn't exist, create it
	insertQuery := `
		INSERT INTO tags (id, name, slug, taggings_count, created_at, updated_at)
		VALUES (gen_random_uuid(), $1, $2, 0, NOW(), NOW())
		RETURNING id, name, slug, taggings_count, created_at, updated_at
	`
	err = r.pool.QueryRow(ctx, insertQuery, name, slug).Scan(
		&tag.ID, &tag.Name, &tag.Slug, &tag.TaggingsCount,
		&tag.CreatedAt, &tag.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create tag: %w", err)
	}

	return &tag, nil
}

// CreateTagging creates a tagging relationship between a post and a tag
func (r *TagRepository) CreateTagging(ctx context.Context, postID, tagID uuid.UUID) error {
	query := `
		INSERT INTO taggings (id, tag_id, taggable_id, taggable_type, created_at)
		VALUES (gen_random_uuid(), $1, $2, 'Post', NOW())
		ON CONFLICT DO NOTHING
	`
	_, err := r.pool.Exec(ctx, query, tagID, postID)
	if err != nil {
		return fmt.Errorf("failed to create tagging: %w", err)
	}
	return nil
}

// DeleteTaggingsForPost removes all tag associations for a post
func (r *TagRepository) DeleteTaggingsForPost(ctx context.Context, postID uuid.UUID) error {
	query := `DELETE FROM taggings WHERE taggable_id = $1 AND taggable_type = 'Post'`
	_, err := r.pool.Exec(ctx, query, postID)
	if err != nil {
		return fmt.Errorf("failed to delete taggings: %w", err)
	}
	return nil
}
