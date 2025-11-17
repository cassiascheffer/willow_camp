package handlers

import (
	"context"
	"fmt"
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

	// Get user's blogs for dropdown
	blogs, err := h.repos.Blog.FindByUserID(c.Request().Context(), user.ID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load blogs")
	}
	user.Blogs = blogs

	// Load all tags for the blog (for choices.js dropdown)
	allTags, err := h.repos.Tag.ListAllForBlog(c.Request().Context(), blogID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load all tags")
	}

	// Prepare dashboard data with navigation
	title := "New Post"
	if blog.Title != nil && *blog.Title != "" {
		title = "New Post - " + *blog.Title
	}
	data, err := h.prepareDashboardData(user, blog, title)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to prepare data")
	}
	data.Post = nil
	data.IsEdit = false
	data.TagsString = ""
	data.AllTags = allTags
	data.ActiveTab = "posts"

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

	// Generate unique slug from title
	baseSlug := slug.Make(title)
	postSlug, err := h.generateUniqueSlug(c.Request().Context(), blogID, user.ID, baseSlug, nil)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to generate slug")
	}

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

// CreateUntitledPost creates a new untitled draft post and redirects to edit
func (h *Handlers) CreateUntitledPost(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	blogID, err := parseUUID(c.Param("blog_id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid blog ID")
	}

	// Verify blog belongs to user
	blog, err := h.repos.Blog.FindByID(c.Request().Context(), blogID)
	if err != nil {
		return echo.NewHTTPError(http.StatusNotFound, "Blog not found")
	}
	if blog.UserID != user.ID {
		return echo.NewHTTPError(http.StatusForbidden, "Access denied")
	}

	// Create untitled post with unique slug using timestamp
	title := "Untitled"
	published := false
	emptyStr := ""
	// Generate unique slug by appending timestamp to avoid conflicts
	uniqueSlug := "untitled-" + time.Now().Format("20060102-150405")

	post := &models.Post{
		ID:           uuid.New(),
		BlogID:       blogID,
		AuthorID:     user.ID,
		Title:        &title,
		Slug:         &uniqueSlug,
		BodyMarkdown: &emptyStr,
		Published:    &published,
	}

	err = h.repos.Post.Create(c.Request().Context(), post)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to create post: "+err.Error())
	}

	// Redirect to edit page
	return c.Redirect(http.StatusFound, "/dashboard/blogs/"+blogID.String()+"/posts/"+post.ID.String()+"/edit")
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

	// Get user's blogs for dropdown
	blogs, err := h.repos.Blog.FindByUserID(c.Request().Context(), user.ID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load blogs")
	}
	user.Blogs = blogs

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

	// Load all tags for the blog (for choices.js dropdown)
	allTags, err := h.repos.Tag.ListAllForBlog(c.Request().Context(), blogID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load all tags")
	}

	// Prepare dashboard data with navigation
	title := "Edit Post"
	if blog.Title != nil && *blog.Title != "" {
		title = "Edit Post - " + *blog.Title
	}
	data, err := h.prepareDashboardData(user, blog, title)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to prepare data")
	}
	data.Post = post
	data.IsEdit = true
	data.TagsString = tagsString
	data.AllTags = allTags
	data.ActiveTab = "posts"

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
		baseSlug := slug.Make(title)
		uniqueSlug, err := h.generateUniqueSlug(c.Request().Context(), post.BlogID, post.AuthorID, baseSlug, &post.ID)
		if err != nil {
			return echo.NewHTTPError(http.StatusInternalServerError, "Failed to generate slug")
		}
		post.Slug = &uniqueSlug
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
		Published       string `json:"published"`     // "on" or empty
		PublishedAt     string `json:"published_at"`  // datetime-local format
		Tags            string `json:"tags"`          // comma-separated tags
		Slug            string `json:"slug"`          // read-only, ignored
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
		baseSlug := slug.Make(req.Title)
		uniqueSlug, err := h.generateUniqueSlug(c.Request().Context(), post.BlogID, post.AuthorID, baseSlug, &post.ID)
		if err != nil {
			c.Logger().Error("AutosavePost: Failed to generate unique slug: ", err)
			return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to generate slug"})
		}
		post.Slug = &uniqueSlug
	}

	// Update fields
	post.Title = &req.Title
	post.BodyMarkdown = &req.BodyMarkdown
	post.MetaDescription = stringPtr(req.MetaDescription)
	post.HasMermaidDiagrams = detectMermaidDiagrams(req.BodyMarkdown)

	published := req.Published == "on"
	post.Published = &published

	// Set published_at if newly published
	if published && (post.PublishedAt == nil) {
		now := time.Now()
		post.PublishedAt = &now
	}

	if err := h.repos.Post.Update(c.Request().Context(), post); err != nil {
		c.Logger().Error("AutosavePost: Failed to update post: ", err)
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to save post"})
	}

	// Handle tags
	if err := h.updatePostTags(c.Request().Context(), post.ID, req.Tags); err != nil {
		c.Logger().Error("AutosavePost: Failed to update tags: ", err)
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to update tags"})
	}

	// Return minimal JSON response including the generated slug
	return c.JSON(http.StatusOK, map[string]interface{}{
		"status":     "saved",
		"updated_at": time.Now(),
		"slug":       *post.Slug,
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

// generateUniqueSlug creates a unique slug by appending numbers if needed
func (h *Handlers) generateUniqueSlug(ctx context.Context, blogID, authorID uuid.UUID, baseSlug string, excludePostID *uuid.UUID) (string, error) {
	// Find the highest numeric suffix for this slug pattern
	maxNum, err := h.repos.Post.FindMaxSlugNumber(ctx, blogID, authorID, baseSlug, excludePostID)
	if err != nil {
		return "", err
	}

	// maxNum == -1: no matching slugs exist, use base slug
	// maxNum == 0: base slug exists but no numbered versions, use baseSlug-1
	// maxNum > 0: numbered versions exist, use baseSlug-(maxNum+1)
	if maxNum == -1 {
		return baseSlug, nil
	}
	return fmt.Sprintf("%s-%d", baseSlug, maxNum+1), nil
}
