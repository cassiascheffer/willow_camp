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

// ListForBlog lists all tags used in a blog with post counts
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
