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

var ErrUserNotFound = errors.New("user not found")

type UserRepository struct {
	pool *pgxpool.Pool
}

func NewUserRepository(pool *pgxpool.Pool) *UserRepository {
	return &UserRepository{pool: pool}
}

// FindByEmail finds a user by email
func (r *UserRepository) FindByEmail(ctx context.Context, email string) (*models.User, error) {
	query := `
		SELECT id, email, encrypted_password, name, reset_password_token,
		       reset_password_sent_at, remember_created_at, sign_in_count,
		       current_sign_in_at, last_sign_in_at, current_sign_in_ip, last_sign_in_ip,
		       confirmation_token, confirmed_at, confirmation_sent_at, unconfirmed_email,
		       blogs_count, created_at, updated_at
		FROM users
		WHERE email = $1
	`

	var user models.User
	err := r.pool.QueryRow(ctx, query, email).Scan(
		&user.ID, &user.Email, &user.EncryptedPassword, &user.Name,
		&user.ResetPasswordToken, &user.ResetPasswordSentAt, &user.RememberCreatedAt,
		&user.SignInCount, &user.CurrentSignInAt, &user.LastSignInAt,
		&user.CurrentSignInIP, &user.LastSignInIP, &user.ConfirmationToken,
		&user.ConfirmedAt, &user.ConfirmationSentAt, &user.UnconfirmedEmail,
		&user.BlogsCount, &user.CreatedAt, &user.UpdatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to find user: %w", err)
	}

	return &user, nil
}

// FindByID finds a user by ID
func (r *UserRepository) FindByID(ctx context.Context, id uuid.UUID) (*models.User, error) {
	query := `
		SELECT id, email, encrypted_password, name, reset_password_token,
		       reset_password_sent_at, remember_created_at, sign_in_count,
		       current_sign_in_at, last_sign_in_at, current_sign_in_ip, last_sign_in_ip,
		       confirmation_token, confirmed_at, confirmation_sent_at, unconfirmed_email,
		       blogs_count, created_at, updated_at
		FROM users
		WHERE id = $1
	`

	var user models.User
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&user.ID, &user.Email, &user.EncryptedPassword, &user.Name,
		&user.ResetPasswordToken, &user.ResetPasswordSentAt, &user.RememberCreatedAt,
		&user.SignInCount, &user.CurrentSignInAt, &user.LastSignInAt,
		&user.CurrentSignInIP, &user.LastSignInIP, &user.ConfirmationToken,
		&user.ConfirmedAt, &user.ConfirmationSentAt, &user.UnconfirmedEmail,
		&user.BlogsCount, &user.CreatedAt, &user.UpdatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to find user: %w", err)
	}

	return &user, nil
}

// Update updates a user
func (r *UserRepository) Update(ctx context.Context, user *models.User) error {
	query := `
		UPDATE users
		SET email = $2, encrypted_password = $3, name = $4, updated_at = NOW()
		WHERE id = $1
	`

	_, err := r.pool.Exec(ctx, query,
		user.ID, user.Email, user.EncryptedPassword, user.Name,
	)

	if err != nil {
		return fmt.Errorf("failed to update user: %w", err)
	}

	return nil
}

// UpdateSignInInfo updates the sign-in tracking fields
func (r *UserRepository) UpdateSignInInfo(ctx context.Context, userID uuid.UUID, ipAddress string) error {
	query := `
		UPDATE users
		SET sign_in_count = sign_in_count + 1,
		    last_sign_in_at = current_sign_in_at,
		    last_sign_in_ip = current_sign_in_ip,
		    current_sign_in_at = NOW(),
		    current_sign_in_ip = $2
		WHERE id = $1
	`

	_, err := r.pool.Exec(ctx, query, userID, ipAddress)
	if err != nil {
		return fmt.Errorf("failed to update sign-in info: %w", err)
	}

	return nil
}
