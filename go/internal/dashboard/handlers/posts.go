package handlers

import (
	"context"
	"fmt"
	"html/template"
	"net/http"
	"strings"
	"time"

	"github.com/cassiascheffer/willow_camp/internal/auth"
	"github.com/cassiascheffer/willow_camp/internal/helpers"
	"github.com/cassiascheffer/willow_camp/internal/markdown"
	"github.com/cassiascheffer/willow_camp/internal/models"
	"github.com/google/uuid"
	"github.com/gosimple/slug"
	"github.com/labstack/echo/v4"
)

// CreateUntitledPost creates a new untitled draft post and redirects to edit
func (h *Handlers) CreateUntitledPost(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	// Get blog by subdomain and verify ownership
	blog, err := h.getBlogBySubdomainParam(c, user)
	if err != nil {
		return err
	}

	// Create untitled post with unique slug using timestamp
	title := "Untitled"
	published := false
	emptyStr := ""
	// Generate unique slug by appending timestamp to avoid conflicts
	uniqueSlug := "untitled-" + time.Now().Format("20060102-150405")

	post := &models.Post{
		ID:           uuid.New(),
		BlogID:       blog.ID,
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
	if blog.Subdomain != nil {
		return c.Redirect(http.StatusFound, "/dashboard/blogs/"+*blog.Subdomain+"/posts/"+post.ID.String()+"/edit")
	}
	return echo.NewHTTPError(http.StatusInternalServerError, "Blog subdomain not found")
}

// EditPost shows the edit post form
func (h *Handlers) EditPost(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	// Get blog by subdomain and verify ownership
	blog, err := h.getBlogBySubdomainParam(c, user)
	if err != nil {
		return err
	}

	postID, err := parseUUID(c.Param("post_id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid post ID")
	}

	post, err := h.repos.Post.FindByID(c.Request().Context(), postID)
	if err != nil || post.BlogID != blog.ID {
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
	allTags, err := h.repos.Tag.ListAllForBlog(c.Request().Context(), blog.ID)
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

// PreviewPost shows a preview of the post using the blog layout
// This allows users to see what their unpublished post will look like when published
func (h *Handlers) PreviewPost(c echo.Context) error {
	logger := getLogger(c)
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	// Get blog by subdomain and verify ownership
	blog, err := h.getBlogBySubdomainParam(c, user)
	if err != nil {
		return err
	}

	// Get post by ID
	postID, err := parseUUID(c.Param("post_id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid post ID")
	}

	post, err := h.repos.Post.FindByID(c.Request().Context(), postID)
	if err != nil || post.BlogID != blog.ID {
		return echo.NewHTTPError(http.StatusNotFound, "Post not found")
	}

	// Render markdown content
	var renderedContent template.HTML
	if post.BodyMarkdown != nil && *post.BodyMarkdown != "" {
		rendered, err := markdown.Render(*post.BodyMarkdown)
		if err != nil {
			logger.Error("Failed to render post markdown", "blog_id", blog.ID, "post_id", post.ID, "error", err)
			return echo.NewHTTPError(http.StatusInternalServerError, "Failed to render markdown")
		}
		renderedContent = rendered
	}

	// Render post footer if present
	var postFooter template.HTML
	if blog.PostFooterMarkdown != nil && *blog.PostFooterMarkdown != "" {
		rendered, err := markdown.Render(*blog.PostFooterMarkdown)
		if err != nil {
			// Don't fail the whole page if footer fails
			logger.Warn("Failed to render post footer markdown", "blog_id", blog.ID, "error", err)
			postFooter = template.HTML("")
		} else {
			postFooter = rendered
		}
	}

	// Load tags for the post
	tags, err := h.repos.Tag.FindTagsForPost(c.Request().Context(), post.ID)
	if err != nil {
		// Don't fail if tags fail to load
		logger.Warn("Failed to load tags for post", "blog_id", blog.ID, "post_id", post.ID, "error", err)
		tags = []models.Tag{}
	}

	// Load author information
	author, err := h.repos.User.FindByID(c.Request().Context(), post.AuthorID)
	var authorName string
	if err == nil && author != nil && author.Name != nil {
		authorName = *author.Name
	}

	// Prepare template data
	title := "Post"
	if post.Title != nil {
		title = *post.Title
	}

	// Set Open Graph type to "article" for posts
	ogType := "article"
	ogDescription := "A blog post powered by willow.camp"
	if post.MetaDescription != nil && *post.MetaDescription != "" {
		ogDescription = *post.MetaDescription
	}

	// Prepare article meta tags
	var articlePublishedTime string
	if post.PublishedAt != nil {
		articlePublishedTime = post.PublishedAt.Format("2006-01-02T15:04:05Z07:00")
	}

	// Collect tag names for article:tag meta tags
	var articleTags []string
	for _, tag := range tags {
		if tag.Name != "" {
			articleTags = append(articleTags, tag.Name)
		}
	}

	// Set meta description for SEO (separate from OGDescription)
	metaDescription := ""
	if post.MetaDescription != nil && *post.MetaDescription != "" {
		metaDescription = *post.MetaDescription
	}

	data := map[string]interface{}{
		"Blog":                 blog,
		"Title":                title,
		"Post":                 post,
		"RenderedContent":      renderedContent,
		"PostFooter":           postFooter,
		"Tags":                 tags,
		"AuthorName":           authorName,
		"OGType":               ogType,
		"OGDescription":        ogDescription,
		"MetaDescription":      metaDescription,
		"ArticlePublishedTime": articlePublishedTime,
		"ArticleAuthor":        authorName,
		"ArticleTags":          articleTags,
	}

	// Set blog in context so the blog template rendering works
	c.Set("blog", blog)

	// Render using the blog layout and template (not dashboard layout)
	return renderBlogTemplate(c, blog, "post_show.html", data)
}

// UpdatePost handles post updates
func (h *Handlers) UpdatePost(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	// Get blog by subdomain and verify ownership
	blog, err := h.getBlogBySubdomainParam(c, user)
	if err != nil {
		return err
	}

	postID, err := parseUUID(c.Param("post_id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid post ID")
	}

	post, err := h.repos.Post.FindByID(c.Request().Context(), postID)
	if err != nil || post.BlogID != blog.ID {
		return echo.NewHTTPError(http.StatusNotFound, "Post not found")
	}

	// Check if this is a JSON request
	isJSON := c.Request().Header.Get("Content-Type") == "application/json"

	var title, bodyMarkdown, metaDescription, tagsInput string
	var published bool

	if isJSON {
		// Parse JSON request
		var req struct {
			Title           string `json:"title"`
			BodyMarkdown    string `json:"body_markdown"`
			MetaDescription string `json:"meta_description"`
			Published       string `json:"published"`
			Tags            string `json:"tags"`
		}
		if err := c.Bind(&req); err != nil {
			return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid request"})
		}
		title = req.Title
		bodyMarkdown = req.BodyMarkdown
		metaDescription = req.MetaDescription
		published = req.Published == "true"
		tagsInput = req.Tags
	} else {
		// Get form data
		title = c.FormValue("title")
		bodyMarkdown = c.FormValue("body_markdown")
		metaDescription = c.FormValue("meta_description")
		published = c.FormValue("published") == "true"
		tagsInput = c.FormValue("tags")
	}

	// Update slug if title changed
	if post.Title == nil || *post.Title != title {
		baseSlug := slug.Make(title)
		uniqueSlug, err := h.generateUniqueSlug(c.Request().Context(), post.BlogID, post.AuthorID, baseSlug, &post.ID)
		if err != nil {
			if isJSON {
				return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to generate slug"})
			}
			return echo.NewHTTPError(http.StatusInternalServerError, "Failed to generate slug")
		}
		post.Slug = &uniqueSlug
	}

	// Update fields
	post.Title = &title
	post.BodyMarkdown = &bodyMarkdown
	post.MetaDescription = stringPtr(metaDescription)
	post.Published = &published
	post.Featured = false
	post.HasMermaidDiagrams = detectMermaidDiagrams(bodyMarkdown)

	// Set published_at if newly published
	if published && (post.PublishedAt == nil) {
		now := time.Now()
		post.PublishedAt = &now
	}

	if err := h.repos.Post.Update(c.Request().Context(), post); err != nil {
		if isJSON {
			return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to update post"})
		}
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to update post")
	}

	// Handle tags
	if err := h.updatePostTags(c.Request().Context(), post.ID, tagsInput); err != nil {
		if isJSON {
			return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to update tags"})
		}
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to update tags")
	}

	// Return JSON response for AJAX requests
	if isJSON {
		publishedAt := ""
		if post.PublishedAt != nil {
			publishedAt = post.PublishedAt.Format("2006-01-02T15:04")
		}
		return c.JSON(http.StatusOK, map[string]interface{}{
			"id":           post.ID.String(),
			"slug":         *post.Slug,
			"published":    *post.Published,
			"published_at": publishedAt,
		})
	}

	// Redirect for traditional form submissions
	if blog.Subdomain != nil {
		return c.Redirect(http.StatusFound, "/dashboard/blogs/"+*blog.Subdomain+"/posts/"+post.ID.String()+"/edit")
	}
	return echo.NewHTTPError(http.StatusInternalServerError, "Blog subdomain not found")
}

// DeletePost handles post deletion
func (h *Handlers) DeletePost(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	// Get blog by subdomain and verify ownership
	blog, err := h.getBlogBySubdomainParam(c, user)
	if err != nil {
		return err
	}

	postID, err := parseUUID(c.Param("post_id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid post ID")
	}

	post, err := h.repos.Post.FindByID(c.Request().Context(), postID)
	if err != nil || post.BlogID != blog.ID {
		return echo.NewHTTPError(http.StatusNotFound, "Post not found")
	}

	if err := h.repos.Post.Delete(c.Request().Context(), postID); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to delete post")
	}

	if blog.Subdomain != nil {
		return c.Redirect(http.StatusFound, "/dashboard/blogs/"+*blog.Subdomain+"/posts")
	}
	return echo.NewHTTPError(http.StatusInternalServerError, "Blog subdomain not found")
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

// renderBlogTemplate renders a blog template with blog layout (not dashboard layout)
// This is used by PreviewPost to show posts as they would appear on the public blog
func renderBlogTemplate(c echo.Context, blog *models.Blog, templateName string, data map[string]interface{}) error {
	logger := getLogger(c)

	// Enrich template data with blog layout requirements
	data = enrichBlogTemplateData(c, blog, data)

	// Create template with helper functions
	tmpl := template.New("layout.html").Funcs(template.FuncMap{
		"add": func(a, b int) int { return a + b },
		"sub": func(a, b int) int { return a - b },
	})

	// Parse blog layout and content templates
	tmpl, err := tmpl.ParseFiles(
		"internal/blog/templates/layout.html",
		"internal/blog/templates/"+templateName,
	)
	if err != nil {
		logger.Error("Failed to parse blog template", "template", templateName, "error", err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Template error: "+err.Error())
	}

	c.Response().Header().Set("Content-Type", "text/html; charset=utf-8")
	c.Response().WriteHeader(http.StatusOK)

	return tmpl.Execute(c.Response().Writer, data)
}

// enrichBlogTemplateData adds layout requirements to template data
// This is similar to the blog handlers' enrichTemplateData but without accessing h.repos
func enrichBlogTemplateData(c echo.Context, blog *models.Blog, data map[string]interface{}) map[string]interface{} {
	// Ensure we have all required fields for the layout
	if _, exists := data["Title"]; !exists {
		data["Title"] = getBlogTitle(blog)
	}

	// Blog title for display
	data["BlogTitle"] = getBlogTitle(blog)

	// OpenMoji favicon filename
	emojiFilename := "1F3D5" // Default camping emoji
	if blog.FaviconEmoji != nil && *blog.FaviconEmoji != "" {
		emojiFilename = helpers.EmojiToOpenmojiFilename(*blog.FaviconEmoji)
	}
	data["EmojiFilename"] = emojiFilename

	// Note: Pages for navigation are not included in preview for simplicity
	// The preview handler can add them if needed
	if _, exists := data["Pages"]; !exists {
		data["Pages"] = []*models.Post{}
	}

	// Open Graph defaults
	if _, exists := data["OGTitle"]; !exists {
		data["OGTitle"] = data["Title"]
	}
	if _, exists := data["OGDescription"]; !exists {
		if blog.MetaDescription != nil && *blog.MetaDescription != "" {
			data["OGDescription"] = *blog.MetaDescription
		} else {
			data["OGDescription"] = "A blog powered by willow.camp"
		}
	}
	if _, exists := data["OGType"]; !exists {
		data["OGType"] = "website"
	}

	// Current URL for Open Graph
	scheme := "http"
	if c.Request().TLS != nil || c.Request().Header.Get("X-Forwarded-Proto") == "https" {
		scheme = "https"
	}
	data["CurrentURL"] = scheme + "://" + c.Request().Host + c.Request().URL.String()

	return data
}

// getBlogTitle returns the blog title for display
func getBlogTitle(blog *models.Blog) string {
	if blog.Title != nil && *blog.Title != "" {
		return *blog.Title
	}
	if blog.Subdomain != nil && *blog.Subdomain != "" {
		return *blog.Subdomain
	}
	if blog.CustomDomain != nil && *blog.CustomDomain != "" {
		return *blog.CustomDomain
	}
	return "willow.camp"
}
