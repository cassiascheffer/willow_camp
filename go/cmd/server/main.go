package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"time"

	"github.com/cassiascheffer/willow_camp/internal/auth"
	"github.com/cassiascheffer/willow_camp/internal/handlers"
	"github.com/cassiascheffer/willow_camp/internal/middleware"
	"github.com/cassiascheffer/willow_camp/internal/repository"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/labstack/echo/v4"
	echomiddleware "github.com/labstack/echo/v4/middleware"
)

func main() {
	// Load environment variables
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL environment variable is required")
	}

	sessionSecret := os.Getenv("SESSION_SECRET")
	if sessionSecret == "" {
		sessionSecret = "dev-secret-change-in-production"
		log.Println("Warning: Using default SESSION_SECRET. Set SESSION_SECRET env var in production!")
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "3001"
	}

	// Initialize database connection pool
	ctx := context.Background()
	pool, err := pgxpool.New(ctx, dbURL)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v\n", err)
	}
	defer pool.Close()

	// Verify database connection
	if err := pool.Ping(ctx); err != nil {
		log.Fatalf("Unable to ping database: %v\n", err)
	}
	log.Println("Successfully connected to database")

	// Initialize repositories
	repos := repository.NewRepositories(pool)

	// Initialize auth
	authService := auth.New(repos.User, sessionSecret)

	// Initialize Echo
	e := echo.New()
	e.HideBanner = true

	// Middleware
	e.Use(echomiddleware.Logger())
	e.Use(echomiddleware.Recover())
	e.Use(echomiddleware.CORS())

	// Static files
	e.Static("/static", "static")

	// Initialize handlers
	h := handlers.New(repos, authService)

	// Auth routes (no blog middleware needed)
	e.GET("/login", h.LoginPage)
	e.POST("/login", h.LoginSubmit)
	e.POST("/logout", h.Logout)
	e.GET("/logout", h.Logout)

	// Dashboard routes (protected)
	dashboard := e.Group("/dashboard")
	dashboard.Use(authService.RequireAuth)
	dashboard.GET("", h.Dashboard)
	dashboard.GET("/blogs/:blog_id/posts", h.BlogPosts)
	dashboard.GET("/blogs/:blog_id/posts/new", h.NewPost)
	dashboard.POST("/blogs/:blog_id/posts", h.CreatePost)
	dashboard.GET("/blogs/:blog_id/posts/:post_id/edit", h.EditPost)
	dashboard.POST("/blogs/:blog_id/posts/:post_id", h.UpdatePost)
	dashboard.POST("/blogs/:blog_id/posts/:post_id/delete", h.DeletePost)

	// Public blog routes (with multi-tenant middleware)
	blog := e.Group("")
	blog.Use(middleware.BlogResolver(repos.Blog))
	blog.GET("/", h.BlogIndex)
	blog.GET("/tags", h.TagsIndex)
	blog.GET("/tags/:tag_slug", h.TagShow)
	blog.GET("/:slug", h.PostShow)

	// Health check
	e.GET("/health", func(c echo.Context) error {
		return c.JSON(http.StatusOK, map[string]string{"status": "ok"})
	})

	// Start server with graceful shutdown
	go func() {
		addr := fmt.Sprintf(":%s", port)
		log.Printf("Starting server on %s", addr)
		if err := e.Start(addr); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server failed to start: %v", err)
		}
	}()

	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt)
	<-quit

	log.Println("Shutting down server...")
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := e.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exited")
}
