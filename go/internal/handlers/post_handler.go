package handlers

import (
	"net/http"
	"time"

	"github.com/cassiascheffer/willow_camp/internal/auth"
	"github.com/cassiascheffer/willow_camp/internal/models"
	"github.com/google/uuid"
	"github.com/gosimple/slug"
	"github.com/labstack/echo/v4"
)

// NewPost shows the new post form
func (h *Handlers) NewPost(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	blogID, err := parseUUID(c.Param("blog_id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid blog ID")
	}

	blog, err := h.repos.Blog.FindByID(c.Request().Context(), blogID)
	if err != nil || blog.UserID != user.ID {
		return echo.NewHTTPError(http.StatusForbidden, "Access denied")
	}

	data := map[string]interface{}{
		"Title":  "New Post",
		"User":   user,
		"Blog":   blog,
		"Post":   nil,
		"IsEdit": false,
	}

	return renderDashboardTemplate(c, "post_form.html", data)
}

// CreatePost handles post creation
func (h *Handlers) CreatePost(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	blogID, err := parseUUID(c.Param("blog_id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid blog ID")
	}

	blog, err := h.repos.Blog.FindByID(c.Request().Context(), blogID)
	if err != nil || blog.UserID != user.ID {
		return echo.NewHTTPError(http.StatusForbidden, "Access denied")
	}

	// Get form data
	title := c.FormValue("title")
	bodyMarkdown := c.FormValue("body_markdown")
	metaDescription := c.FormValue("meta_description")
	published := c.FormValue("published") == "on"
	featured := c.FormValue("featured") == "on"

	// Generate slug from title
	postSlug := slug.Make(title)

	// Create post
	post := &models.Post{
		ID:              uuid.New(),
		BlogID:          blogID,
		AuthorID:        user.ID,
		Title:           &title,
		Slug:            &postSlug,
		BodyMarkdown:    &bodyMarkdown,
		MetaDescription: stringPtr(metaDescription),
		Published:       &published,
		Featured:        featured,
		Type:            stringPtr("Post"),
	}

	if published {
		now := time.Now()
		post.PublishedAt = &now
	}

	if err := h.repos.Post.Create(c.Request().Context(), post); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to create post")
	}

	return c.Redirect(http.StatusFound, "/dashboard/blogs/"+blogID.String()+"/posts")
}

// EditPost shows the edit post form
func (h *Handlers) EditPost(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	blogID, err := parseUUID(c.Param("blog_id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid blog ID")
	}

	postID, err := parseUUID(c.Param("post_id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid post ID")
	}

	blog, err := h.repos.Blog.FindByID(c.Request().Context(), blogID)
	if err != nil || blog.UserID != user.ID {
		return echo.NewHTTPError(http.StatusForbidden, "Access denied")
	}

	post, err := h.repos.Post.FindByID(c.Request().Context(), postID)
	if err != nil || post.BlogID != blogID {
		return echo.NewHTTPError(http.StatusNotFound, "Post not found")
	}

	data := map[string]interface{}{
		"Title":  "Edit Post",
		"User":   user,
		"Blog":   blog,
		"Post":   post,
		"IsEdit": true,
	}

	return renderDashboardTemplate(c, "post_form.html", data)
}

// UpdatePost handles post updates
func (h *Handlers) UpdatePost(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	blogID, err := parseUUID(c.Param("blog_id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid blog ID")
	}

	postID, err := parseUUID(c.Param("post_id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid post ID")
	}

	blog, err := h.repos.Blog.FindByID(c.Request().Context(), blogID)
	if err != nil || blog.UserID != user.ID {
		return echo.NewHTTPError(http.StatusForbidden, "Access denied")
	}

	post, err := h.repos.Post.FindByID(c.Request().Context(), postID)
	if err != nil || post.BlogID != blogID {
		return echo.NewHTTPError(http.StatusNotFound, "Post not found")
	}

	// Get form data
	title := c.FormValue("title")
	bodyMarkdown := c.FormValue("body_markdown")
	metaDescription := c.FormValue("meta_description")
	published := c.FormValue("published") == "on"
	featured := c.FormValue("featured") == "on"

	// Update slug if title changed
	if post.Title == nil || *post.Title != title {
		postSlug := slug.Make(title)
		post.Slug = &postSlug
	}

	// Update fields
	post.Title = &title
	post.BodyMarkdown = &bodyMarkdown
	post.MetaDescription = stringPtr(metaDescription)
	post.Published = &published
	post.Featured = featured

	// Set published_at if newly published
	if published && (post.PublishedAt == nil) {
		now := time.Now()
		post.PublishedAt = &now
	}

	if err := h.repos.Post.Update(c.Request().Context(), post); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to update post")
	}

	return c.Redirect(http.StatusFound, "/dashboard/blogs/"+blogID.String()+"/posts")
}

func stringPtr(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}
