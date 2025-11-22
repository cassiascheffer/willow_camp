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
	"github.com/cassiascheffer/willow_camp/internal/logging"
	"github.com/cassiascheffer/willow_camp/internal/models"
	"github.com/cassiascheffer/willow_camp/internal/repository"
	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
)

// Handlers holds dashboard handler dependencies
type Handlers struct {
	repos      *repository.Repositories
	auth       *auth.Auth
	baseDomain string
}

// New creates a new dashboard Handlers instance
func New(repos *repository.Repositories, authService *auth.Auth, baseDomain string) *Handlers {
	return &Handlers{
		repos:      repos,
		auth:       authService,
		baseDomain: baseDomain,
	}
}

// getLogger retrieves the logger from the Echo context
func getLogger(c echo.Context) *logging.Logger {
	if logger, ok := c.Get("logger").(*logging.Logger); ok {
		return logger
	}
	// Fallback to a new logger if not found in context
	return logging.NewLogger()
}

// getTitle returns the blog title for display
func getTitle(blog *models.Blog) string {
	if blog == nil {
		return "willow.camp"
	}
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

func parseUUID(s string) (uuid.UUID, error) {
	return uuid.Parse(s)
}

// getBlogBySubdomainParam fetches a blog by the :subdomain route parameter and verifies ownership
func (h *Handlers) getBlogBySubdomainParam(c echo.Context, user *models.User) (*models.Blog, error) {
	logger := getLogger(c)
	subdomain := c.Param("subdomain")
	if subdomain == "" {
		logger.Warn("Invalid blog subdomain parameter", "user_id", user.ID)
		return nil, echo.NewHTTPError(http.StatusBadRequest, "Invalid blog subdomain")
	}

	blog, err := h.repos.Blog.FindBySubdomain(c.Request().Context(), subdomain)
	if err != nil {
		logger.Warn("Blog not found by subdomain", "subdomain", subdomain, "user_id", user.ID, "error", err)
		return nil, echo.NewHTTPError(http.StatusNotFound, "Blog not found")
	}

	if blog.UserID != user.ID {
		logger.Warn("User attempted to access blog they don't own", "user_id", user.ID, "blog_id", blog.ID, "blog_owner_id", blog.UserID)
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
	Title           string
	User            *models.User
	Blog            *models.Blog
	Blogs           []*models.Blog
	Posts           []*models.Post
	Post            *models.Post
	ActiveTab       string
	NavTitle        string
	NavPath         string
	EmojiFilename   string
	IsEdit          bool
	TagsString      string
	AllTags         []string // All tag names for the blog (for choices.js)
	BaseDomain      string
	ShowNewBlogForm bool
	ErrorMessage    string
	SuccessMessage  string
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

// renderDashboardTemplate renders a dashboard template with layout
func renderDashboardTemplate(c echo.Context, templateName string, data interface{}) error {
	logger := getLogger(c)

	// Dashboard template rendering with custom functions
	tmpl := template.New("layout.html").Funcs(templateFuncs())

	// Parse dashboard layout and content templates
	tmpl, err := tmpl.ParseFiles(
		"internal/dashboard/templates/layout.html",
		"internal/dashboard/templates/"+templateName,
	)
	if err != nil {
		logger.Error("Failed to parse dashboard template", "template", templateName, "error", err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Template error: "+err.Error())
	}

	c.Response().Header().Set("Content-Type", "text/html; charset=utf-8")
	c.Response().WriteHeader(http.StatusOK)

	return tmpl.Execute(c.Response().Writer, data)
}
