package handlers

import (
	"html/template"
	"net/http"
	"strconv"

	"github.com/cassiascheffer/willow_camp/internal/blog/middleware"
	"github.com/cassiascheffer/willow_camp/internal/markdown"
	"github.com/cassiascheffer/willow_camp/internal/models"
	"github.com/labstack/echo/v4"
)

// BlogIndex shows the blog's published posts
// If no blog is resolved (root domain), shows the home/landing page instead
func (h *Handlers) BlogIndex(c echo.Context) error {
	blog := middleware.GetBlog(c)
	if blog == nil {
		// No blog in context means we're on the root domain (willow.camp or localhost)
		// Show the marketing/landing page
		if h.homeHandler != nil {
			return h.homeHandler(c)
		}
		return echo.NewHTTPError(http.StatusNotFound, "Blog not found")
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

	logger := getLogger(c)

	// Fetch featured posts (up to 3)
	featuredPosts, err := h.repos.Post.ListFeatured(c.Request().Context(), blog.ID, 3)
	if err != nil {
		// Don't fail if featured posts fail to load
		logger.Warn("Failed to load featured posts", "blog_id", blog.ID, "error", err)
		featuredPosts = []*models.Post{}
	}

	// Fetch published posts
	posts, err := h.repos.Post.ListPublished(c.Request().Context(), blog.ID, postsPerPage, offset)
	if err != nil {
		logger.Error("Failed to load posts", "blog_id", blog.ID, "page", page, "offset", offset, "error", err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load posts")
	}

	// Get total count for pagination
	totalPosts, err := h.repos.Post.CountPublished(c.Request().Context(), blog.ID)
	if err != nil {
		logger.Error("Failed to count posts", "blog_id", blog.ID, "error", err)
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

	return h.renderTemplate(c, "index.html", data)
}

// PostShow shows a single post
func (h *Handlers) PostShow(c echo.Context) error {
	logger := getLogger(c)
	blog := middleware.GetBlog(c)
	if blog == nil {
		logger.Error("Blog not found in context for post show")
		return echo.NewHTTPError(http.StatusInternalServerError, "Blog not found in context")
	}

	slug := c.Param("slug")

	// Fetch post by slug
	post, err := h.repos.Post.FindBySlug(c.Request().Context(), blog.ID, slug)
	if err != nil {
		logger.Warn("Post not found by slug", "blog_id", blog.ID, "slug", slug, "error", err)
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
			logger.Error("Failed to render post markdown", "blog_id", blog.ID, "post_id", post.ID, "slug", slug, "error", err)
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

	return h.renderTemplate(c, "post_show.html", data)
}
