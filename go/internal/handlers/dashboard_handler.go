package handlers

import (
	"html/template"
	"net/http"
	"sort"
	"strings"

	"github.com/cassiascheffer/willow_camp/internal/auth"
	"github.com/cassiascheffer/willow_camp/internal/helpers"
	"github.com/cassiascheffer/willow_camp/internal/models"
	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
)

func parseUUID(s string) (uuid.UUID, error) {
	return uuid.Parse(s)
}

// sortBlogsByTitle sorts blogs alphabetically by title (or subdomain if no title)
func sortBlogsByTitle(blogs []*models.Blog) {
	sort.Slice(blogs, func(i, j int) bool {
		titleI := ""
		if blogs[i].Title != nil && *blogs[i].Title != "" {
			titleI = *blogs[i].Title
		} else if blogs[i].Subdomain != nil {
			titleI = *blogs[i].Subdomain
		}

		titleJ := ""
		if blogs[j].Title != nil && *blogs[j].Title != "" {
			titleJ = *blogs[j].Title
		} else if blogs[j].Subdomain != nil {
			titleJ = *blogs[j].Subdomain
		}

		return strings.ToLower(titleI) < strings.ToLower(titleJ)
	})
}

// dashboardTemplateData holds all data needed for dashboard layout
type dashboardTemplateData struct {
	Title         string
	User          *models.User
	Blog          *models.Blog
	Blogs         []*models.Blog
	Posts         []*models.Post
	ActiveTab     string
	NavTitle      string
	NavPath       string
	EmojiFilename string
}

// prepareDashboardData populates common dashboard layout data
func (h *Handlers) prepareDashboardData(user *models.User, blog *models.Blog, title string) (*dashboardTemplateData, error) {
	data := &dashboardTemplateData{
		Title: title,
		User:  user,
		Blog:  blog,
	}

	// Set navigation title and path
	if blog != nil {
		if blog.Title != nil && *blog.Title != "" {
			data.NavTitle = *blog.Title
		} else if blog.Subdomain != nil {
			data.NavTitle = *blog.Subdomain
		} else {
			data.NavTitle = "willow.camp"
		}
		data.NavPath = "/dashboard/blogs/" + blog.ID.String() + "/posts"

		// Set emoji filename for favicon
		emoji := "🏕️" // Default camping emoji
		if blog.FaviconEmoji != nil && *blog.FaviconEmoji != "" {
			emoji = *blog.FaviconEmoji
		}
		data.EmojiFilename = helpers.EmojiToOpenmojiFilename(emoji)
	} else {
		data.NavTitle = "willow.camp"
		data.NavPath = "/dashboard"
		data.EmojiFilename = helpers.EmojiToOpenmojiFilename("🏕️")
	}

	return data, nil
}

// Dashboard shows the main dashboard
func (h *Handlers) Dashboard(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	// Get user's blogs
	blogs, err := h.repos.Blog.FindByUserID(c.Request().Context(), user.ID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load blogs")
	}

	// If user has no blogs, show error
	if len(blogs) == 0 {
		return echo.NewHTTPError(http.StatusNotFound, "No blogs found")
	}

	// Redirect to default blog (primary blog or first blog)
	// FindByUserID orders by "primary" DESC, created_at ASC, so the first blog is the default
	return c.Redirect(http.StatusFound, "/dashboard/blogs/"+blogs[0].ID.String()+"/posts")
}

// BlogPosts shows the post list for a specific blog
func (h *Handlers) BlogPosts(c echo.Context) error {
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

	// Get user's blogs for dropdown
	blogs, err := h.repos.Blog.FindByUserID(c.Request().Context(), user.ID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load blogs")
	}

	// Sort blogs by title for display (matching Rails behavior)
	sortBlogsByTitle(blogs)
	user.Blogs = blogs

	// Get all posts (including drafts) for this blog
	posts, err := h.repos.Post.ListAll(c.Request().Context(), blogID, 100, 0)
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

// templateFuncs returns custom template functions for dashboard templates
func templateFuncs() template.FuncMap {
	return template.FuncMap{
		"heroicon": func(name string, class string) template.HTML {
			return helpers.Icon("24/outline/"+name, class)
		},
		"heroiconMini": func(name string, class string) template.HTML {
			return helpers.Icon("20/solid/"+name, class)
		},
		"hasText": func(s *string) bool {
			return s != nil && *s != ""
		},
		"allThemes": func() []string {
			return helpers.AllThemes()
		},
	}
}

func renderDashboardTemplate(c echo.Context, templateName string, data interface{}) error {
	// Dashboard template rendering with custom functions
	tmpl := template.New("dashboard_layout.html").Funcs(templateFuncs())

	// Parse dashboard layout and content templates
	tmpl, err := tmpl.ParseFiles(
		"internal/templates/dashboard_layout.html",
		"internal/templates/"+templateName,
	)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Template error: "+err.Error())
	}

	c.Response().Header().Set("Content-Type", "text/html; charset=utf-8")
	c.Response().WriteHeader(http.StatusOK)

	return tmpl.Execute(c.Response().Writer, data)
}
