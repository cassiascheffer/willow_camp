package handlers

import (
	"net/http"
	"strconv"

	"github.com/cassiascheffer/willow_camp/internal/middleware"
	"github.com/cassiascheffer/willow_camp/internal/models"
	"github.com/labstack/echo/v4"
)

// TagsIndex shows all tags for the blog
func (h *Handlers) TagsIndex(c echo.Context) error {
	blog := middleware.GetBlog(c)
	if blog == nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Blog not found in context")
	}

	// Get all tags used in this blog
	tags, err := h.repos.Tag.ListForBlog(c.Request().Context(), blog.ID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load tags")
	}

	data := map[string]interface{}{
		"Blog":  blog,
		"Title": "Tags - " + getTitle(blog),
		"Tags":  tags,
	}

	return renderTemplate(c, "tags_index.html", data)
}

// TagShow shows posts for a specific tag
func (h *Handlers) TagShow(c echo.Context) error {
	blog := middleware.GetBlog(c)
	if blog == nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Blog not found in context")
	}

	tagSlug := c.Param("tag_slug")

	// Get page number from query param
	page := 1
	if pageStr := c.QueryParam("page"); pageStr != "" {
		if p, err := strconv.Atoi(pageStr); err == nil && p > 0 {
			page = p
		}
	}

	// Calculate offset
	offset := (page - 1) * postsPerPage

	// For now, we'll fetch all posts and filter by tag in memory
	// TODO: Optimize with a proper query
	allPosts, err := h.repos.Post.ListPublished(c.Request().Context(), blog.ID, 10000, 0)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load posts")
	}

	// Load tags for each post and filter
	var filteredPosts []*models.Post
	var tagName string
	for _, post := range allPosts {
		tags, err := h.repos.Tag.FindTagsForPost(c.Request().Context(), post.ID)
		if err != nil {
			continue
		}

		// Check if this post has the requested tag
		for _, tag := range tags {
			if tag.Slug != nil && *tag.Slug == tagSlug {
				post.Tags = tags
				filteredPosts = append(filteredPosts, post)
				if tagName == "" {
					tagName = tag.Name
				}
				break
			}
		}
	}

	// Apply pagination to filtered results
	totalPosts := len(filteredPosts)
	totalPages := (totalPosts + postsPerPage - 1) / postsPerPage

	// Slice the filtered posts for the current page
	start := offset
	end := offset + postsPerPage
	if start > totalPosts {
		start = totalPosts
	}
	if end > totalPosts {
		end = totalPosts
	}
	paginatedPosts := filteredPosts[start:end]

	data := map[string]interface{}{
		"Blog":        blog,
		"Title":       "Posts tagged \"" + tagName + "\" - " + getTitle(blog),
		"Posts":       paginatedPosts,
		"TagName":     tagName,
		"CurrentPage": page,
		"TotalPages":  totalPages,
	}

	return renderTemplate(c, "tag_show.html", data)
}
