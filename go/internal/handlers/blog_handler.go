package handlers

import (
	"html/template"
	"net/http"
	"strconv"

	"github.com/cassiascheffer/willow_camp/internal/helpers"
	"github.com/cassiascheffer/willow_camp/internal/markdown"
	"github.com/cassiascheffer/willow_camp/internal/middleware"
	"github.com/cassiascheffer/willow_camp/internal/models"
	"github.com/labstack/echo/v4"
)

const postsPerPage = 50

// BlogIndex shows the blog's published posts
func (h *Handlers) BlogIndex(c echo.Context) error {
	blog := middleware.GetBlog(c)
	if blog == nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Blog not found in context")
	}

	// Get page number from query param
	page := 1
	if pageStr := c.QueryParam("page"); pageStr != "" {
		if p, err := strconv.Atoi(pageStr); err == nil && p > 0 {
			page = p
		}
	}

	// Calculate offset
	offset := (page - 1) * postsPerPage

	// Fetch featured posts (up to 3)
	featuredPosts, err := h.repos.Post.ListFeatured(c.Request().Context(), blog.ID, 3)
	if err != nil {
		// Don't fail if featured posts fail to load
		featuredPosts = []*models.Post{}
	}

	// Fetch published posts
	posts, err := h.repos.Post.ListPublished(c.Request().Context(), blog.ID, postsPerPage, offset)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load posts")
	}

	// Get total count for pagination
	totalPosts, err := h.repos.Post.CountPublished(c.Request().Context(), blog.ID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to count posts")
	}

	totalPages := (totalPosts + postsPerPage - 1) / postsPerPage

	// Prepare template data
	data := map[string]interface{}{
		"Blog":          blog,
		"Title":         getTitle(blog) + " | Posts",
		"FeaturedPosts": featuredPosts,
		"Posts":         posts,
		"CurrentPage":   page,
		"TotalPages":    totalPages,
	}

	return renderTemplate(c, "blog_index.html", data)
}

// PostShow shows a single post
func (h *Handlers) PostShow(c echo.Context) error {
	blog := middleware.GetBlog(c)
	if blog == nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Blog not found in context")
	}

	slug := c.Param("slug")

	// Fetch post by slug
	post, err := h.repos.Post.FindBySlug(c.Request().Context(), blog.ID, slug)
	if err != nil {
		return echo.NewHTTPError(http.StatusNotFound, "Post not found")
	}

	// Check if post is published (unless we add auth later for previewing drafts)
	if !post.IsPublished() {
		return echo.NewHTTPError(http.StatusNotFound, "Post not found")
	}

	// Render markdown content
	var renderedContent template.HTML
	if post.BodyMarkdown != nil && *post.BodyMarkdown != "" {
		rendered, err := markdown.Render(*post.BodyMarkdown)
		if err != nil {
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
			postFooter = template.HTML("")
		} else {
			postFooter = rendered
		}
	}

	// Load tags for the post
	tags, err := h.repos.Tag.FindTagsForPost(c.Request().Context(), post.ID)
	if err != nil {
		// Don't fail if tags fail to load
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
		"ArticlePublishedTime": articlePublishedTime,
		"ArticleAuthor":        authorName,
		"ArticleTags":          articleTags,
	}

	return renderTemplate(c, "post_show.html", data)
}

// Helper functions

func getTitle(blog *models.Blog) string {
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

func enrichTemplateData(c echo.Context, blog *models.Blog, data map[string]interface{}) map[string]interface{} {
	// Ensure we have all required fields for the layout
	if _, exists := data["Title"]; !exists {
		data["Title"] = getTitle(blog)
	}

	// Blog title for display
	data["BlogTitle"] = getTitle(blog)

	// OpenMoji favicon filename
	emojiFilename := "1F3D5" // Default camping emoji
	if blog.FaviconEmoji != nil && *blog.FaviconEmoji != "" {
		emojiFilename = helpers.EmojiToOpenmojiFilename(*blog.FaviconEmoji)
	}
	data["EmojiFilename"] = emojiFilename

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

func renderTemplate(c echo.Context, templateName string, data interface{}) error {
	// Convert data to map and enrich with layout requirements
	blog := middleware.GetBlog(c)
	dataMap, ok := data.(map[string]interface{})
	if !ok {
		dataMap = map[string]interface{}{"Data": data}
	}

	if blog != nil {
		dataMap = enrichTemplateData(c, blog, dataMap)
	}

	// Create template with helper functions
	tmpl := template.New("layout.html").Funcs(template.FuncMap{
		"add": func(a, b int) int { return a + b },
		"sub": func(a, b int) int { return a - b },
	})

	// Parse layout and content templates
	tmpl, err := tmpl.ParseFiles(
		"internal/templates/layout.html",
		"internal/templates/"+templateName,
	)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Template error: "+err.Error())
	}

	c.Response().Header().Set("Content-Type", "text/html; charset=utf-8")
	c.Response().WriteHeader(http.StatusOK)

	return tmpl.Execute(c.Response().Writer, dataMap)
}

func renderSimpleTemplate(c echo.Context, templateName string, data interface{}) error {
	// Simple template rendering without blog layout (for auth pages, etc.)
	tmpl := template.New("simple_layout.html")

	// Parse simple layout and content templates
	tmpl, err := tmpl.ParseFiles(
		"internal/templates/simple_layout.html",
		"internal/templates/"+templateName,
	)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Template error: "+err.Error())
	}

	c.Response().Header().Set("Content-Type", "text/html; charset=utf-8")
	c.Response().WriteHeader(http.StatusOK)

	return tmpl.Execute(c.Response().Writer, data)
}
