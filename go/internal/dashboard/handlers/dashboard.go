package handlers

import (
	"net/http"
	"strings"

	"github.com/cassiascheffer/willow_camp/internal/auth"
	"github.com/labstack/echo/v4"
)

// Dashboard shows the main dashboard for the default blog
func (h *Handlers) Dashboard(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	logger := getLogger(c)

	// Check for new_blog query parameter
	showNewBlogForm := c.QueryParam("new_blog") == "true"

	// Get user's blogs
	blogs, err := h.repos.Blog.FindByUserID(c.Request().Context(), user.ID)
	if err != nil {
		logger.Error("Failed to load blogs for user", "user_id", user.ID, "error", err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load blogs")
	}

	// Sort blogs by title for display (matching Rails behavior)
	sortBlogsByTitle(blogs)
	user.Blogs = blogs

	// If user has no blogs or new_blog=true, show the new blog form
	if len(blogs) == 0 || showNewBlogForm {
		data, err := h.prepareDashboardData(user, nil, "Your Blogs")
		if err != nil {
			logger.Error("Failed to prepare dashboard data", "user_id", user.ID, "error", err)
			return echo.NewHTTPError(http.StatusInternalServerError, "Failed to prepare data")
		}
		data.ShowNewBlogForm = true
		data.Blogs = blogs

		// Get error/success messages from query params
		errorParam := c.QueryParam("error")
		if errorParam != "" {
			data.ErrorMessage = getErrorMessage(errorParam)
		}
		successParam := c.QueryParam("success")
		if successParam != "" {
			data.SuccessMessage = getSuccessMessage(successParam)
		}

		return renderDashboardTemplate(c, "index.html", data)
	}

	// Use default blog (primary blog or first blog)
	// FindByUserID orders by "primary" DESC, created_at ASC, so the first blog is the default
	defaultBlog := blogs[0]

	// Get all posts (including drafts) for the default blog
	posts, err := h.repos.Post.ListAll(c.Request().Context(), defaultBlog.ID, 100, 0)
	if err != nil {
		logger.Error("Failed to load posts for blog", "blog_id", defaultBlog.ID, "user_id", user.ID, "error", err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load posts")
	}

	// Prepare dashboard data
	title := "Posts"
	if defaultBlog.Title != nil && *defaultBlog.Title != "" {
		title = "Posts - " + *defaultBlog.Title
	} else if defaultBlog.Subdomain != nil {
		title = "Posts - " + *defaultBlog.Subdomain
	}

	data, err := h.prepareDashboardData(user, defaultBlog, title)
	if err != nil {
		logger.Error("Failed to prepare dashboard data", "blog_id", defaultBlog.ID, "user_id", user.ID, "error", err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to prepare data")
	}
	data.Posts = posts
	data.ActiveTab = "posts"

	return renderDashboardTemplate(c, "posts_list.html", data)
}

// getErrorMessage converts error codes to user-friendly messages
func getErrorMessage(code string) string {
	messages := map[string]string{
		"subdomain_required":  "Subdomain is required",
		"subdomain_length":    "Subdomain must be between 3 and 63 characters",
		"subdomain_format":    "Subdomain can only contain lowercase letters and numbers",
		"subdomain_taken":     "This subdomain is already taken",
		"creation_failed":     "Failed to create blog. Please try again.",
	}
	if msg, ok := messages[code]; ok {
		return msg
	}
	return "An error occurred"
}

// getSuccessMessage converts success codes to user-friendly messages
func getSuccessMessage(code string) string {
	messages := map[string]string{
		"blog_created": "Blog created successfully!",
	}
	if msg, ok := messages[code]; ok {
		return msg
	}
	return ""
}

// CreateBlog handles creation of a new blog
func (h *Handlers) CreateBlog(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	subdomain := strings.TrimSpace(c.FormValue("subdomain"))
	primaryStr := c.FormValue("primary")

	// Validate subdomain
	if subdomain == "" {
		return c.Redirect(http.StatusFound, "/dashboard?new_blog=true&error=subdomain_required")
	}

	// Convert to lowercase
	subdomain = strings.ToLower(subdomain)

	// Validate subdomain format (3-63 chars, alphanumeric only)
	if len(subdomain) < 3 || len(subdomain) > 63 {
		return c.Redirect(http.StatusFound, "/dashboard?new_blog=true&error=subdomain_length")
	}

	// Check alphanumeric only
	for _, ch := range subdomain {
		if !((ch >= 'a' && ch <= 'z') || (ch >= '0' && ch <= '9')) {
			return c.Redirect(http.StatusFound, "/dashboard?new_blog=true&error=subdomain_format")
		}
	}

	// Check if subdomain already exists
	existingBlog, err := h.repos.Blog.FindBySubdomain(c.Request().Context(), subdomain)
	if err == nil && existingBlog != nil {
		return c.Redirect(http.StatusFound, "/dashboard?new_blog=true&error=subdomain_taken")
	}

	// Parse primary flag
	primary := primaryStr == "true"

	// Create the blog
	_, err = h.repos.Blog.Create(c.Request().Context(), user.ID, subdomain, primary)
	if err != nil {
		return c.Redirect(http.StatusFound, "/dashboard?new_blog=true&error=creation_failed")
	}

	// Redirect to the new blog's dashboard
	return c.Redirect(http.StatusFound, "/dashboard/blogs/"+subdomain+"/posts")
}

// BlogPosts shows the post list for a specific blog
func (h *Handlers) BlogPosts(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	// Get blog by subdomain and verify ownership
	blog, err := h.getBlogBySubdomainParam(c, user)
	if err != nil {
		return err
	}

	// Get user's blogs for dropdown
	blogs, err := h.repos.Blog.FindByUserID(c.Request().Context(), user.ID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load blogs")
	}

	// Sort blogs by title for display (matching Rails behavior)
	sortBlogsByTitle(blogs)
	user.Blogs = blogs

	// Get all posts (including drafts) for this blog
	posts, err := h.repos.Post.ListAll(c.Request().Context(), blog.ID, 100, 0)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load posts")
	}

	// Prepare dashboard data
	title := "Posts"
	if blog.Title != nil && *blog.Title != "" {
		title = "Posts - " + *blog.Title
	} else if blog.Subdomain != nil {
		title = "Posts - " + *blog.Subdomain
	}

	data, err := h.prepareDashboardData(user, blog, title)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to prepare data")
	}
	data.Posts = posts
	data.ActiveTab = "posts"

	return renderDashboardTemplate(c, "posts_list.html", data)
}
