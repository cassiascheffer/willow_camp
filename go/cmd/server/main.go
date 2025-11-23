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
	bloghandlers "github.com/cassiascheffer/willow_camp/internal/blog/handlers"
	blogmiddleware "github.com/cassiascheffer/willow_camp/internal/blog/middleware"
	dashboardhandlers "github.com/cassiascheffer/willow_camp/internal/dashboard/handlers"
	"github.com/cassiascheffer/willow_camp/internal/logging"
	"github.com/cassiascheffer/willow_camp/internal/repository"
	sharedhandlers "github.com/cassiascheffer/willow_camp/internal/shared/handlers"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/labstack/echo/v4"
	echomiddleware "github.com/labstack/echo/v4/middleware"
)

func main() {
	// Initialize structured logger
	logger := logging.NewLogger()

	// Load environment variables
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL environment variable is required")
	}

	sessionSecret := os.Getenv("SESSION_SECRET")
	if sessionSecret == "" {
		sessionSecret = "dev-secret-change-in-production"
		logger.Warn("Using default SESSION_SECRET", "message", "Set SESSION_SECRET env var in production!")
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "3001"
	}

	baseDomain := os.Getenv("BASE_DOMAIN")
	if baseDomain == "" {
		baseDomain = "localhost:3001"
		logger.Info("Using default BASE_DOMAIN", "domain", baseDomain, "message", "set BASE_DOMAIN env var for production")
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
	logger.Info("Successfully connected to database")

	// Initialize repositories
	repos := repository.NewRepositories(pool)

	// Initialize auth
	authService := auth.New(repos.User, sessionSecret, logger)

	// Initialize Echo
	e := echo.New()
	e.HideBanner = true

	// Middleware
	e.Use(logging.RequestLogger(logger))
	e.Use(echomiddleware.Recover())
	e.Use(echomiddleware.RemoveTrailingSlash())
	e.Use(echomiddleware.CORS())
	e.Use(echomiddleware.Gzip())
	e.Use(echomiddleware.Secure())
	// Make logger available in context
	e.Use(func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			c.Set("logger", logger)
			return next(c)
		}
	})

	// Static files
	e.Static("/static", "static")
	// OpenMoji assets from Rails public directory
	e.Static("/openmoji-32x32-ico", "../public/openmoji-32x32-ico")
	e.Static("/openmoji-svg-color", "../public/openmoji-svg-color")
	e.Static("/openmoji-apple-touch-icon-180x180", "../public/openmoji-apple-touch-icon-180x180")
	e.File("/openmoji-map.json", "../public/openmoji-map.json")

	// Initialize handlers
	blogH := bloghandlers.New(repos, authService, baseDomain)
	dashboardH := dashboardhandlers.New(repos, authService, baseDomain)
	sharedH := sharedhandlers.New(repos, authService, baseDomain)

	// Set home handler for blog (so BlogIndex can call it when on root domain)
	blogH.SetHomeHandler(sharedH.HomePage)

	// Auth routes (no blog middleware needed)
	e.GET("/login", sharedH.LoginPage)
	e.POST("/login", sharedH.LoginSubmit)
	e.POST("/logout", sharedH.Logout)
	e.GET("/logout", sharedH.Logout)

	// Dashboard routes (protected)
	dashboard := e.Group("/dashboard")
	dashboard.Use(authService.RequireAuth)
	dashboard.GET("", dashboardH.Dashboard)
	dashboard.GET("/", dashboardH.Dashboard)
	dashboard.POST("/blogs", dashboardH.CreateBlog)
	dashboard.GET("/blogs/:subdomain/posts", dashboardH.BlogPosts)
	dashboard.POST("/blogs/:subdomain/posts/untitled", dashboardH.CreateUntitledPost)
	dashboard.GET("/blogs/:subdomain/posts/:post_id/edit", dashboardH.EditPost)
	dashboard.GET("/blogs/:subdomain/posts/:post_id/preview", dashboardH.PreviewPost)
	dashboard.POST("/blogs/:subdomain/posts/:post_id", dashboardH.UpdatePost)
	dashboard.PUT("/blogs/:subdomain/posts/:post_id", dashboardH.UpdatePost)
	dashboard.POST("/blogs/:subdomain/posts/:post_id/delete", dashboardH.DeletePost)
	dashboard.GET("/blogs/:subdomain/settings", dashboardH.BlogSettings)
	dashboard.POST("/blogs/:subdomain/settings", dashboardH.UpdateBlogSettings)
	dashboard.POST("/blogs/:subdomain/settings/favicon", dashboardH.UpdateFaviconEmoji)
	dashboard.POST("/blogs/:subdomain/settings/about", dashboardH.UpdateAboutPage)
	dashboard.POST("/blogs/:subdomain/settings/about/delete", dashboardH.DeleteAboutPage)
	dashboard.POST("/blogs/:subdomain/delete", dashboardH.DeleteBlog)
	dashboard.GET("/blogs/:subdomain/tags", dashboardH.DashboardTagsIndex)
	dashboard.PATCH("/blogs/:subdomain/tags/:tag_id", dashboardH.UpdateTag)
	dashboard.PUT("/blogs/:subdomain/tags/:tag_id", dashboardH.UpdateTag)
	dashboard.DELETE("/blogs/:subdomain/tags/:tag_id", dashboardH.DeleteTag)
	dashboard.GET("/security", dashboardH.Security)
	dashboard.POST("/security/profile", dashboardH.UpdateProfile)
	dashboard.POST("/security/password", dashboardH.UpdateSecurityPassword)
	dashboard.GET("/tokens", dashboardH.GetTokens)
	dashboard.POST("/tokens", dashboardH.CreateToken)
	dashboard.POST("/tokens/:id/delete", dashboardH.DeleteToken)

	// Public blog routes (with multi-tenant middleware)
	blog := e.Group("")
	blog.Use(blogmiddleware.BlogResolver(repos.Blog))
	blog.GET("/", blogH.BlogIndex)
	blog.GET("/feed.rss", blogH.RSSFeed)
	blog.GET("/feed.atom", blogH.AtomFeed)
	blog.GET("/feed.json", blogH.JSONFeed)
	blog.GET("/subscribe", blogH.Subscribe)
	blog.GET("/sitemap.xml", blogH.Sitemap)
	blog.GET("/robots.txt", blogH.RobotsTxt)
	blog.GET("/tags", blogH.TagsIndex)
	blog.GET("/tags/:tag_slug", blogH.TagShow)
	blog.GET("/:slug", blogH.PostShow)

	// Health check
	e.GET("/health", func(c echo.Context) error {
		return c.JSON(http.StatusOK, map[string]string{"status": "ok"})
	})

	// Start server with graceful shutdown
	go func() {
		addr := fmt.Sprintf(":%s", port)
		logger.Info("Starting server", "address", addr)
		if err := e.Start(addr); err != nil && err != http.ErrServerClosed {
			logger.Error("Server failed to start", "error", err)
			log.Fatalf("Server failed to start: %v", err)
		}
	}()

	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt)
	<-quit

	logger.Info("Shutting down server...")
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := e.Shutdown(ctx); err != nil {
		logger.Error("Server forced to shutdown", "error", err)
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	logger.Info("Server exited")
}
