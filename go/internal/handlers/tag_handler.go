package handlers

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/cassiascheffer/willow_camp/internal/auth"
	"github.com/cassiascheffer/willow_camp/internal/middleware"
	"github.com/cassiascheffer/willow_camp/internal/models"
	"github.com/google/uuid"
	"github.com/gosimple/slug"
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

	return h.renderTemplate(c, "tags_index.html", data)
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

	return h.renderTemplate(c, "tag_show.html", data)
}

// DashboardTagsIndex shows all tags for a blog in the dashboard
func (h *Handlers) DashboardTagsIndex(c echo.Context) error {
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

	// Sort blogs by title for display
	sortBlogsByTitle(blogs)
	user.Blogs = blogs

	// Get all tags with counts for this blog
	tags, err := h.repos.Tag.ListWithCountsForBlog(c.Request().Context(), blog.ID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load tags")
	}

	// Prepare dashboard data
	title := "Tags"
	if blog.Title != nil && *blog.Title != "" {
		title = "Tags - " + *blog.Title
	} else if blog.Subdomain != nil {
		title = "Tags - " + *blog.Subdomain
	}

	data, err := h.prepareDashboardData(user, blog, title)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to prepare data")
	}
	data.ActiveTab = "tags"

	// Add tags to template data
	type tagTemplateData struct {
		*dashboardTemplateData
		Tags []models.TagWithCounts
	}

	templateData := &tagTemplateData{
		dashboardTemplateData: data,
		Tags:                  tags,
	}

	return renderDashboardTemplate(c, "tags_list.html", templateData)
}

// UpdateTag updates a tag's name via AJAX
func (h *Handlers) UpdateTag(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return c.JSON(http.StatusUnauthorized, map[string]string{"error": "Unauthorized"})
	}

	// Get blog by subdomain and verify ownership
	_, err := h.getBlogBySubdomainParam(c, user)
	if err != nil {
		return c.JSON(http.StatusForbidden, map[string]string{"error": "Access denied"})
	}

	// Get tag ID from URL parameter
	tagIDStr := c.Param("tag_id")
	tagID, err := uuid.Parse(tagIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid tag ID"})
	}

	// Get new tag name from request body
	var request struct {
		Name string `json:"name"`
	}
	if err := c.Bind(&request); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid request"})
	}

	// Validate tag name
	newName := strings.TrimSpace(request.Name)
	if newName == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Tag name cannot be empty"})
	}

	// Generate slug from name
	tagSlug := slug.Make(newName)

	// Update the tag
	err = h.repos.Tag.UpdateTag(c.Request().Context(), tagID, newName, tagSlug)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to update tag"})
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
		"name":    newName,
		"slug":    tagSlug,
	})
}

// DeleteTag deletes a tag via AJAX
func (h *Handlers) DeleteTag(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return c.JSON(http.StatusUnauthorized, map[string]string{"error": "Unauthorized"})
	}

	// Get blog by subdomain and verify ownership
	_, err := h.getBlogBySubdomainParam(c, user)
	if err != nil {
		return c.JSON(http.StatusForbidden, map[string]string{"error": "Access denied"})
	}

	// Get tag ID from URL parameter
	tagIDStr := c.Param("tag_id")
	tagID, err := uuid.Parse(tagIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid tag ID"})
	}

	// Delete the tag
	err = h.repos.Tag.DeleteTag(c.Request().Context(), tagID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to delete tag"})
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"success": true,
	})
}
