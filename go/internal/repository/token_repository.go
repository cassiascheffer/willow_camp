package repository

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"time"

	"github.com/cassiascheffer/willow_camp/internal/models"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var ErrTokenNotFound = errors.New("token not found")

type TokenRepository struct {
	pool *pgxpool.Pool
}

func NewTokenRepository(pool *pgxpool.Pool) *TokenRepository {
	return &TokenRepository{pool: pool}
}

// FindByUserID returns all tokens for a user, ordered by creation date
func (r *TokenRepository) FindByUserID(ctx context.Context, userID uuid.UUID) ([]*models.UserToken, error) {
	query := `
		SELECT id, user_id, token, name, expires_at, created_at, updated_at
		FROM user_tokens
		WHERE user_id = $1
		ORDER BY created_at DESC
	`

	rows, err := r.pool.Query(ctx, query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to query tokens: %w", err)
	}
	defer rows.Close()

	// Initialize as empty slice so JSON marshals to [] instead of null
	tokens := []*models.UserToken{}
	for rows.Next() {
		var token models.UserToken
		err := rows.Scan(
			&token.ID, &token.UserID, &token.Token, &token.Name,
			&token.ExpiresAt, &token.CreatedAt, &token.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan token: %w", err)
		}
		tokens = append(tokens, &token)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating tokens: %w", err)
	}

	return tokens, nil
}

// Create creates a new token for a user
func (r *TokenRepository) Create(ctx context.Context, userID uuid.UUID, name string, expiresAt *time.Time) (*models.UserToken, error) {
	// Generate a random 32-character hex token (16 bytes)
	tokenBytes := make([]byte, 16)
	if _, err := rand.Read(tokenBytes); err != nil {
		return nil, fmt.Errorf("failed to generate token: %w", err)
	}
	tokenString := hex.EncodeToString(tokenBytes)

	query := `
		INSERT INTO user_tokens (user_id, token, name, expires_at, created_at, updated_at)
		VALUES ($1, $2, $3, $4, NOW(), NOW())
		RETURNING id, user_id, token, name, expires_at, created_at, updated_at
	`

	var token models.UserToken
	err := r.pool.QueryRow(ctx, query, userID, tokenString, name, expiresAt).Scan(
		&token.ID, &token.UserID, &token.Token, &token.Name,
		&token.ExpiresAt, &token.CreatedAt, &token.UpdatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to create token: %w", err)
	}

	return &token, nil
}

// Delete deletes a token by ID
func (r *TokenRepository) Delete(ctx context.Context, tokenID uuid.UUID, userID uuid.UUID) error {
	query := `
		DELETE FROM user_tokens
		WHERE id = $1 AND user_id = $2
	`

	result, err := r.pool.Exec(ctx, query, tokenID, userID)
	if err != nil {
		return fmt.Errorf("failed to delete token: %w", err)
	}

	if result.RowsAffected() == 0 {
		return ErrTokenNotFound
	}

	return nil
}

// FindByToken finds a token by its token string (for authentication)
func (r *TokenRepository) FindByToken(ctx context.Context, token string) (*models.UserToken, error) {
	query := `
		SELECT id, user_id, token, name, expires_at, created_at, updated_at
		FROM user_tokens
		WHERE token = $1
	`

	var userToken models.UserToken
	err := r.pool.QueryRow(ctx, query, token).Scan(
		&userToken.ID, &userToken.UserID, &userToken.Token, &userToken.Name,
		&userToken.ExpiresAt, &userToken.CreatedAt, &userToken.UpdatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrTokenNotFound
		}
		return nil, fmt.Errorf("failed to find token: %w", err)
	}

	// Check if token is expired
	if userToken.ExpiresAt != nil && userToken.ExpiresAt.Before(time.Now()) {
		return nil, ErrTokenNotFound
	}

	return &userToken, nil
}
