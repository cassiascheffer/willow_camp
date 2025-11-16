package handlers

import (
	"context"
	"net/http"
	"strings"
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
		"Title":      "New Post",
		"User":       user,
		"Blog":       blog,
		"Post":       nil,
		"IsEdit":     false,
		"TagsString": "",
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
	tagsInput := c.FormValue("tags")

	// Generate slug from title
	postSlug := slug.Make(title)

	// Create post
	post := &models.Post{
		ID:                 uuid.New(),
		BlogID:             blogID,
		AuthorID:           user.ID,
		Title:              &title,
		Slug:               &postSlug,
		BodyMarkdown:       &bodyMarkdown,
		MetaDescription:    stringPtr(metaDescription),
		Published:          &published,
		Featured:           featured,
		Type:               stringPtr("Post"),
		HasMermaidDiagrams: detectMermaidDiagrams(bodyMarkdown),
	}

	if published {
		now := time.Now()
		post.PublishedAt = &now
	}

	if err := h.repos.Post.Create(c.Request().Context(), post); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to create post")
	}

	// Handle tags
	if err := h.updatePostTags(c.Request().Context(), post.ID, tagsInput); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to update tags")
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

	// Load tags for this post
	tags, err := h.repos.Tag.FindTagsForPost(c.Request().Context(), postID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load tags")
	}

	// Convert tags to comma-separated string
	tagNames := make([]string, len(tags))
	for i, tag := range tags {
		tagNames[i] = tag.Name
	}
	tagsString := ""
	if len(tagNames) > 0 {
		tagsString = joinStrings(tagNames, ", ")
	}

	data := map[string]interface{}{
		"Title":      "Edit Post",
		"User":       user,
		"Blog":       blog,
		"Post":       post,
		"IsEdit":     true,
		"TagsString": tagsString,
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
	tagsInput := c.FormValue("tags")

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
	post.HasMermaidDiagrams = detectMermaidDiagrams(bodyMarkdown)

	// Set published_at if newly published
	if published && (post.PublishedAt == nil) {
		now := time.Now()
		post.PublishedAt = &now
	}

	if err := h.repos.Post.Update(c.Request().Context(), post); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to update post")
	}

	// Handle tags
	if err := h.updatePostTags(c.Request().Context(), post.ID, tagsInput); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to update tags")
	}

	return c.Redirect(http.StatusFound, "/dashboard/blogs/"+blogID.String()+"/posts")
}

// AutosavePost handles autosave for post editing
func (h *Handlers) AutosavePost(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return c.JSON(http.StatusUnauthorized, map[string]string{"error": "Unauthorized"})
	}

	blogID, err := parseUUID(c.Param("blog_id"))
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid blog ID"})
	}

	postID, err := parseUUID(c.Param("post_id"))
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid post ID"})
	}

	blog, err := h.repos.Blog.FindByID(c.Request().Context(), blogID)
	if err != nil || blog.UserID != user.ID {
		return c.JSON(http.StatusForbidden, map[string]string{"error": "Access denied"})
	}

	post, err := h.repos.Post.FindByID(c.Request().Context(), postID)
	if err != nil || post.BlogID != blogID {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "Post not found"})
	}

	// Parse JSON request body
	var req struct {
		Title           string `json:"title"`
		BodyMarkdown    string `json:"body_markdown"`
		MetaDescription string `json:"meta_description"`
		Published       string `json:"published"` // "on" or empty
		Featured        string `json:"featured"`  // "on" or empty
	}

	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid request body"})
	}

	// Validate required fields
	if req.Title == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Title is required"})
	}

	// Update slug if title changed
	if post.Title == nil || *post.Title != req.Title {
		postSlug := slug.Make(req.Title)
		post.Slug = &postSlug
	}

	// Update fields
	post.Title = &req.Title
	post.BodyMarkdown = &req.BodyMarkdown
	post.MetaDescription = stringPtr(req.MetaDescription)
	post.HasMermaidDiagrams = detectMermaidDiagrams(req.BodyMarkdown)

	published := req.Published == "on"
	post.Published = &published
	post.Featured = req.Featured == "on"

	// Set published_at if newly published
	if published && (post.PublishedAt == nil) {
		now := time.Now()
		post.PublishedAt = &now
	}

	if err := h.repos.Post.Update(c.Request().Context(), post); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to save post"})
	}

	// Return minimal JSON response
	return c.JSON(http.StatusOK, map[string]interface{}{
		"status":     "saved",
		"updated_at": time.Now(),
	})
}

// DeletePost handles post deletion
func (h *Handlers) DeletePost(c echo.Context) error {
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

	if err := h.repos.Post.Delete(c.Request().Context(), postID); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to delete post")
	}

	return c.Redirect(http.StatusFound, "/dashboard/blogs/"+blogID.String()+"/posts")
}

func stringPtr(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}

// detectMermaidDiagrams checks if markdown contains mermaid diagrams
func detectMermaidDiagrams(markdown string) bool {
	return strings.Contains(markdown, "```mermaid")
}

func joinStrings(strs []string, sep string) string {
	result := ""
	for i, s := range strs {
		if i > 0 {
			result += sep
		}
		result += s
	}
	return result
}

// updatePostTags handles tag creation and association for a post
func (h *Handlers) updatePostTags(ctx context.Context, postID uuid.UUID, tagsInput string) error {
	// Delete existing taggings
	if err := h.repos.Tag.DeleteTaggingsForPost(ctx, postID); err != nil {
		return err
	}

	// Parse tags from input (comma-separated)
	if tagsInput == "" {
		return nil
	}

	tagNames := strings.Split(tagsInput, ",")
	for _, tagName := range tagNames {
		tagName = strings.TrimSpace(tagName)
		if tagName == "" {
			continue
		}

		// Create slug for tag
		tagSlug := slug.Make(tagName)

		// Find or create tag
		tag, err := h.repos.Tag.FindOrCreateByName(ctx, tagName, tagSlug)
		if err != nil {
			return err
		}

		// Create tagging
		if err := h.repos.Tag.CreateTagging(ctx, postID, tag.ID); err != nil {
			return err
		}
	}

	return nil
}
