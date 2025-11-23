package auth

import (
	"errors"
	"net/http"

	"github.com/cassiascheffer/willow_camp/internal/logging"
	"github.com/cassiascheffer/willow_camp/internal/models"
	"github.com/cassiascheffer/willow_camp/internal/repository"
	"github.com/google/uuid"
	"github.com/gorilla/sessions"
	"github.com/labstack/echo/v4"
	"golang.org/x/crypto/bcrypt"
)

const (
	sessionName      = "willow_camp_session"
	sessionUserIDKey = "user_id"
)

var (
	ErrInvalidCredentials = errors.New("invalid email or password")
	ErrUnauthorized       = errors.New("unauthorized")
)

// Auth handles authentication
type Auth struct {
	userRepo *repository.UserRepository
	store    *sessions.CookieStore
	logger   *logging.Logger
}

// New creates a new Auth instance
func New(userRepo *repository.UserRepository, sessionSecret string, logger *logging.Logger) *Auth {
	// Create cookie store with secret
	store := sessions.NewCookieStore([]byte(sessionSecret))
	store.Options = &sessions.Options{
		Path:     "/",
		MaxAge:   86400 * 7, // 7 days
		HttpOnly: true,
		Secure:   false, // Set to true in production with HTTPS
		SameSite: http.SameSiteLaxMode,
	}

	return &Auth{
		userRepo: userRepo,
		store:    store,
		logger:   logger,
	}
}

// Login authenticates a user and creates a session
func (a *Auth) Login(c echo.Context, email, password string) (*models.User, error) {
	// Find user by email
	user, err := a.userRepo.FindByEmail(c.Request().Context(), email)
	if err != nil {
		if errors.Is(err, repository.ErrUserNotFound) {
			return nil, ErrInvalidCredentials
		}
		return nil, err
	}

	// Verify password (Rails Devise uses bcrypt)
	if err := bcrypt.CompareHashAndPassword([]byte(user.EncryptedPassword), []byte(password)); err != nil {
		return nil, ErrInvalidCredentials
	}

	// Create session
	session, err := a.store.Get(c.Request(), sessionName)
	if err != nil {
		return nil, err
	}

	session.Values[sessionUserIDKey] = user.ID.String()
	if err := session.Save(c.Request(), c.Response()); err != nil {
		return nil, err
	}

	// Update sign-in tracking
	ip := c.RealIP()
	if err := a.userRepo.UpdateSignInInfo(c.Request().Context(), user.ID, ip); err != nil {
		a.logger.Warn("Failed to update sign-in tracking", "user_id", user.ID, "ip", ip, "error", err)
	}

	return user, nil
}

// Logout destroys the user session
func (a *Auth) Logout(c echo.Context) error {
	session, err := a.store.Get(c.Request(), sessionName)
	if err != nil {
		return err
	}

	session.Options.MaxAge = -1
	delete(session.Values, sessionUserIDKey)

	return session.Save(c.Request(), c.Response())
}

// GetCurrentUser retrieves the current authenticated user from session
func (a *Auth) GetCurrentUser(c echo.Context) (*models.User, error) {
	session, err := a.store.Get(c.Request(), sessionName)
	if err != nil {
		return nil, err
	}

	userIDStr, ok := session.Values[sessionUserIDKey].(string)
	if !ok {
		return nil, ErrUnauthorized
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		return nil, ErrUnauthorized
	}

	user, err := a.userRepo.FindByID(c.Request().Context(), userID)
	if err != nil {
		if errors.Is(err, repository.ErrUserNotFound) {
			return nil, ErrUnauthorized
		}
		return nil, err
	}

	return user, nil
}

// RequireAuth is middleware that requires authentication
func (a *Auth) RequireAuth(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		user, err := a.GetCurrentUser(c)
		if err != nil {
			// Redirect to login
			return c.Redirect(http.StatusFound, "/login")
		}

		// Store user in context
		c.Set("current_user", user)
		return next(c)
	}
}

// GetUser retrieves the current user from Echo context (set by RequireAuth middleware)
func GetUser(c echo.Context) *models.User {
	user, ok := c.Get("current_user").(*models.User)
	if !ok {
		return nil
	}
	return user
}
