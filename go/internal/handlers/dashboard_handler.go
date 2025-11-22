package handlers

import (
	"encoding/json"
	"html/template"
	"net/http"
	"sort"
	"strings"
	"time"

	"github.com/cassiascheffer/willow_camp/internal/auth"
	"github.com/cassiascheffer/willow_camp/internal/helpers"
	"github.com/cassiascheffer/willow_camp/internal/models"
	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
)

func parseUUID(s string) (uuid.UUID, error) {
	return uuid.Parse(s)
}

// getBlogBySubdomainParam fetches a blog by the :subdomain route parameter and verifies ownership
func (h *Handlers) getBlogBySubdomainParam(c echo.Context, user *models.User) (*models.Blog, error) {
	subdomain := c.Param("subdomain")
	if subdomain == "" {
		return nil, echo.NewHTTPError(http.StatusBadRequest, "Invalid blog subdomain")
	}

	blog, err := h.repos.Blog.FindBySubdomain(c.Request().Context(), subdomain)
	if err != nil {
		return nil, echo.NewHTTPError(http.StatusNotFound, "Blog not found")
	}

	if blog.UserID != user.ID {
		return nil, echo.NewHTTPError(http.StatusForbidden, "Access denied")
	}

	return blog, nil
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
	Title            string
	User             *models.User
	Blog             *models.Blog
	Blogs            []*models.Blog
	Posts            []*models.Post
	Post             *models.Post
	ActiveTab        string
	NavTitle         string
	NavPath          string
	EmojiFilename    string
	IsEdit           bool
	TagsString       string
	AllTags          []string // All tag names for the blog (for choices.js)
	BaseDomain       string
	ShowNewBlogForm  bool
	ErrorMessage     string
	SuccessMessage   string
}

// prepareDashboardData populates common dashboard layout data
func (h *Handlers) prepareDashboardData(user *models.User, blog *models.Blog, title string) (*dashboardTemplateData, error) {
	data := &dashboardTemplateData{
		Title:      title,
		User:       user,
		Blog:       blog,
		BaseDomain: h.baseDomain,
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
		if blog.Subdomain != nil {
			data.NavPath = "/dashboard/blogs/" + *blog.Subdomain + "/posts"
		} else {
			data.NavPath = "/dashboard"
		}

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

// Dashboard shows the main dashboard for the default blog
func (h *Handlers) Dashboard(c echo.Context) error {
	user := auth.GetUser(c)
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	// Check for new_blog query parameter
	showNewBlogForm := c.QueryParam("new_blog") == "true"

	// Get user's blogs
	blogs, err := h.repos.Blog.FindByUserID(c.Request().Context(), user.ID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load blogs")
	}

	// Sort blogs by title for display (matching Rails behavior)
	sortBlogsByTitle(blogs)
	user.Blogs = blogs

	// If user has no blogs or new_blog=true, show the new blog form
	if len(blogs) == 0 || showNewBlogForm {
		data, err := h.prepareDashboardData(user, nil, "Your Blogs")
		if err != nil {
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

		return renderDashboardTemplate(c, "dashboard_index.html", data)
	}

	// Use default blog (primary blog or first blog)
	// FindByUserID orders by "primary" DESC, created_at ASC, so the first blog is the default
	defaultBlog := blogs[0]

	// Get all posts (including drafts) for the default blog
	posts, err := h.repos.Post.ListAll(c.Request().Context(), defaultBlog.ID, 100, 0)
	if err != nil {
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

// templateFuncs returns custom template functions for dashboard templates
func templateFuncs() template.FuncMap {
	return template.FuncMap{
		"heroicon": func(name string, class string) template.HTML {
			return helpers.Icon("24/outline/"+name, class)
		},
		"heroiconMini": func(name string, class string) template.HTML {
			return helpers.Icon("20/solid/"+name, class)
		},
		"blogURL": func(subdomain string, baseDomain string) string {
			// Use http:// for localhost, https:// for everything else
			protocol := "https://"
			if strings.Contains(baseDomain, "localhost") {
				protocol = "http://"
			}
			return protocol + subdomain + "." + baseDomain + "/"
		},
		"postURL": func(subdomain string, slug string, baseDomain string) string {
			// Use http:// for localhost, https:// for everything else
			protocol := "https://"
			if strings.Contains(baseDomain, "localhost") {
				protocol = "http://"
			}
			return protocol + subdomain + "." + baseDomain + "/" + slug
		},
		"hasText": func(s *string) bool {
			return s != nil && *s != ""
		},
		"allThemes": func() []string {
			return helpers.AllThemes()
		},
		"deref": func(ptr interface{}) interface{} {
			if ptr == nil {
				return nil
			}
			switch v := ptr.(type) {
			case *string:
				if v == nil {
					return ""
				}
				return *v
			case *bool:
				if v == nil {
					return false
				}
				return *v
			case *int:
				if v == nil {
					return 0
				}
				return *v
			default:
				return ptr
			}
		},
		"formatDateTime": func(t *time.Time) string {
			if t == nil {
				return ""
			}
			// Format as "2006-01-02T15:04" for datetime-local input
			return t.Format("2006-01-02T15:04")
		},
		"formatDate": func(t interface{}) string {
			switch v := t.(type) {
			case time.Time:
				return v.Format("Jan 02, 2006")
			case *time.Time:
				if v == nil {
					return ""
				}
				return v.Format("Jan 02, 2006")
			default:
				return ""
			}
		},
		"toJSON": func(v interface{}) (template.JS, error) {
			bytes, err := json.Marshal(v)
			if err != nil {
				return "", err
			}
			return template.JS(bytes), nil
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
