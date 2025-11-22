package tests

import (
	"context"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"

	"github.com/cassiascheffer/willow_camp/internal/auth"
	"github.com/cassiascheffer/willow_camp/internal/handlers"
	"github.com/cassiascheffer/willow_camp/internal/middleware"
	"github.com/cassiascheffer/willow_camp/internal/repository"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/labstack/echo/v4"
	echomiddleware "github.com/labstack/echo/v4/middleware"
)

// setupTestServer creates a test server with database connection
func setupTestServer(t *testing.T) (*echo.Echo, *repository.Repositories) {
	// Use DATABASE_URL from environment (shared with development)
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		dbURL = "postgres://localhost/willow_camp_development?sslmode=disable"
	}

	ctx := context.Background()
	pool, err := pgxpool.New(ctx, dbURL)
	if err != nil {
		t.Skipf("Skipping integration test - cannot connect to database: %v", err)
	}

	if err := pool.Ping(ctx); err != nil {
		t.Skipf("Skipping integration test - cannot ping database: %v", err)
	}

	// Initialize repositories
	repos := repository.NewRepositories(pool)

	// Initialize auth with test secret
	authService := auth.New(repos.User, "test-secret")

	// Initialize Echo app
	e := echo.New()
	e.HideBanner = true
	e.Use(echomiddleware.Recover())

	// Initialize handlers
	h := handlers.New(repos, authService)

	// Setup routes
	setupRoutes(e, h, authService, repos)

	return e, repos
}

func setupRoutes(e *echo.Echo, h *handlers.Handlers, authService *auth.Auth, repos *repository.Repositories) {
	// Auth routes
	e.GET("/login", h.LoginPage)
	e.POST("/login", h.LoginSubmit)
	e.POST("/logout", h.Logout)
	e.GET("/logout", h.Logout)

	// Dashboard routes (protected)
	dashboard := e.Group("/dashboard")
	dashboard.Use(authService.RequireAuth)
	dashboard.GET("", h.Dashboard)
	dashboard.GET("/blogs/:blog_id/posts", h.BlogPosts)
	dashboard.POST("/blogs/:blog_id/posts/untitled", h.CreateUntitledPost)
	dashboard.GET("/blogs/:blog_id/posts/:post_id/edit", h.EditPost)
	dashboard.POST("/blogs/:blog_id/posts/:post_id", h.UpdatePost)
	dashboard.PUT("/blogs/:blog_id/posts/:post_id", h.UpdatePost)
	dashboard.POST("/blogs/:blog_id/posts/:post_id/delete", h.DeletePost)
	dashboard.GET("/blogs/:blog_id/settings", h.BlogSettings)
	dashboard.POST("/blogs/:blog_id/settings", h.UpdateBlogSettings)
	dashboard.GET("/settings", h.UserSettings)
	dashboard.POST("/settings", h.UpdateUserSettings)
	dashboard.POST("/settings/password", h.UpdatePassword)

	// Public blog routes
	blog := e.Group("")
	blog.Use(middleware.BlogResolver(repos.Blog))
	blog.GET("/", h.BlogIndex)
	blog.GET("/:slug", h.PostShow)
}

func stringPtr(s string) *string {
	return &s
}

// TestAuthenticationFlow tests login page is accessible
func TestAuthenticationFlow(t *testing.T) {
	app, _ := setupTestServer(t)

	t.Run("LoginPage_Returns200", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/login", nil)
		rec := httptest.NewRecorder()
		app.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Errorf("Expected status 200 for login page, got %d", rec.Code)
		}

		body := rec.Body.String()
		if !strings.Contains(body, "login") && !strings.Contains(body, "Login") {
			t.Error("Expected login page to contain 'login' text")
		}
	})

	t.Run("ProtectedRoute_RedirectsToLogin", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/dashboard", nil)
		rec := httptest.NewRecorder()
		app.ServeHTTP(rec, req)

		// Should redirect to login when not authenticated
		if rec.Code != http.StatusFound && rec.Code != http.StatusSeeOther {
			t.Errorf("Expected redirect status for protected route, got %d", rec.Code)
		}

		location := rec.Header().Get("Location")
		if !strings.Contains(location, "login") {
			t.Errorf("Expected redirect to login page, got %s", location)
		}
	})
}

// TestPublicRoutes tests that public blog routes return appropriate responses
func TestPublicRoutes(t *testing.T) {
	app, _ := setupTestServer(t)

	t.Run("BlogIndex_WithoutValidDomain_ReturnsError", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/", nil)
		req.Host = "nonexistent-blog.willow.camp"
		rec := httptest.NewRecorder()
		app.ServeHTTP(rec, req)

		// Should return an error for nonexistent blog
		if rec.Code == http.StatusOK {
			t.Error("Expected error status for nonexistent blog")
		}
	})
}

// TestTemplateRendering tests that templates render without errors
func TestTemplateRendering(t *testing.T) {
	app, _ := setupTestServer(t)

	testCases := []struct {
		name     string
		path     string
		wantCode int
	}{
		{"LoginPage", "/login", http.StatusOK},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodGet, tc.path, nil)
			rec := httptest.NewRecorder()
			app.ServeHTTP(rec, req)

			if rec.Code != tc.wantCode {
				t.Errorf("Expected status %d for %s, got %d", tc.wantCode, tc.path, rec.Code)
			}

			// Check that response is HTML
			contentType := rec.Header().Get("Content-Type")
			if !strings.Contains(contentType, "text/html") && rec.Code == http.StatusOK {
				t.Errorf("Expected HTML content type, got %s", contentType)
			}
		})
	}
}

// TestRepositories tests that repository methods work correctly
func TestRepositories(t *testing.T) {
	_, repos := setupTestServer(t)
	ctx := context.Background()

	t.Run("FindBlogByDomain", func(t *testing.T) {
		// Test with a bogus domain - should return error
		_, err := repos.Blog.FindByDomain(ctx, "nonexistent-test-blog")
		if err == nil {
			t.Error("Expected error for nonexistent blog")
		}
	})

	t.Run("FindUserByID", func(t *testing.T) {
		// Test with random UUID - should return error
		randomID := uuid.New()
		_, err := repos.User.FindByID(ctx, randomID)
		if err == nil {
			t.Error("Expected error for nonexistent user")
		}
	})
}

// TestDatabaseConnection verifies database connectivity
func TestDatabaseConnection(t *testing.T) {
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		dbURL = "postgres://localhost/willow_camp_development?sslmode=disable"
	}

	ctx := context.Background()
	pool, err := pgxpool.New(ctx, dbURL)
	if err != nil {
		t.Fatalf("Failed to connect to database: %v", err)
	}
	defer pool.Close()

	if err := pool.Ping(ctx); err != nil {
		t.Fatalf("Failed to ping database: %v", err)
	}

	// Test a simple query
	var result int
	err = pool.QueryRow(ctx, "SELECT 1").Scan(&result)
	if err != nil {
		t.Fatalf("Failed to execute test query: %v", err)
	}

	if result != 1 {
		t.Errorf("Expected result 1, got %d", result)
	}
}
