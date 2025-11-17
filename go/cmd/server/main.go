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
	poolConfig, err := pgxpool.ParseConfig(dbURL)
	if err != nil {
		log.Fatalf("Unable to parse database URL: %v\n", err)
	}

	// Configure pool for performance
	poolConfig.MaxConns = 25
	poolConfig.MinConns = 5
	poolConfig.MaxConnLifetime = 5 * time.Minute
	poolConfig.MaxConnIdleTime = 1 * time.Minute

	pool, err := pgxpool.NewWithConfig(ctx, poolConfig)
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
	e.Use(echomiddleware.Gzip())
	e.Use(echomiddleware.Secure())

	// Static files
	e.Static("/static", "static")
	// OpenMoji assets from Rails public directory
	e.Static("/openmoji-32x32-ico", "../public/openmoji-32x32-ico")
	e.Static("/openmoji-svg-color", "../public/openmoji-svg-color")
	e.Static("/openmoji-apple-touch-icon-180x180", "../public/openmoji-apple-touch-icon-180x180")
	e.File("/openmoji-map.json", "../public/openmoji-map.json")

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
	dashboard.GET("/blogs/:subdomain/posts", h.BlogPosts)
	dashboard.POST("/blogs/:subdomain/posts/untitled", h.CreateUntitledPost)
	dashboard.GET("/blogs/:subdomain/posts/:post_id/edit", h.EditPost)
	dashboard.POST("/blogs/:subdomain/posts/:post_id", h.UpdatePost)
	dashboard.PUT("/blogs/:subdomain/posts/:post_id/autosave", h.AutosavePost)
	dashboard.POST("/blogs/:subdomain/posts/:post_id/delete", h.DeletePost)
	dashboard.GET("/blogs/:subdomain/settings", h.BlogSettings)
	dashboard.POST("/blogs/:subdomain/settings", h.UpdateBlogSettings)
	dashboard.POST("/blogs/:subdomain/settings/about", h.UpdateAboutPage)
	dashboard.POST("/blogs/:subdomain/settings/about/delete", h.DeleteAboutPage)
	dashboard.POST("/blogs/:subdomain/delete", h.DeleteBlog)
	dashboard.GET("/settings", h.UserSettings)
	dashboard.POST("/settings", h.UpdateUserSettings)
	dashboard.POST("/settings/password", h.UpdatePassword)

	// Public blog routes (with multi-tenant middleware)
	blog := e.Group("")
	blog.Use(middleware.BlogResolver(repos.Blog))
	blog.GET("/", h.BlogIndex)
	blog.GET("/feed.xml", h.RSSFeed)
	blog.GET("/sitemap.xml", h.Sitemap)
	blog.GET("/robots.txt", h.RobotsTxt)
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
