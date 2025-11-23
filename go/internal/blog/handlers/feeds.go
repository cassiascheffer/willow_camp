package handlers

import (
	"encoding/xml"
	"net/http"
	"time"

	"github.com/cassiascheffer/willow_camp/internal/blog/middleware"
	"github.com/cassiascheffer/willow_camp/internal/helpers"
	"github.com/cassiascheffer/willow_camp/internal/markdown"
	"github.com/cassiascheffer/willow_camp/internal/models"
	"github.com/labstack/echo/v4"
)

// RSS 2.0 feed structures
type RSS struct {
	XMLName xml.Name `xml:"rss"`
	Version string   `xml:"version,attr"`
	Atom    string   `xml:"xmlns:atom,attr"`
	Channel *Channel `xml:"channel"`
}

type Channel struct {
	Title       string     `xml:"title"`
	Link        string     `xml:"link"`
	Description string     `xml:"description"`
	Language    string     `xml:"language"`
	AtomLink    *AtomLink  `xml:"atom:link"`
	Items       []RSSItem  `xml:"item"`
}

type AtomLink struct {
	Href string `xml:"href,attr"`
	Rel  string `xml:"rel,attr"`
	Type string `xml:"type,attr"`
}

type RSSItem struct {
	Title       string `xml:"title"`
	Link        string `xml:"link"`
	Description string `xml:"description"`
	PubDate     string `xml:"pubDate"`
	GUID        string `xml:"guid"`
}

// Atom feed structures
type AtomFeed struct {
	XMLName  xml.Name     `xml:"feed"`
	Xmlns    string       `xml:"xmlns,attr"`
	ID       string       `xml:"id"`
	Title    string       `xml:"title"`
	Updated  string       `xml:"updated"`
	Author   *AtomAuthor  `xml:"author"`
	Links    []AtomLink   `xml:"link"`
	Subtitle string       `xml:"subtitle"`
	Entries  []AtomEntry  `xml:"entry"`
}

type AtomAuthor struct {
	Name string `xml:"name"`
}

type AtomEntry struct {
	ID      string      `xml:"id"`
	Title   string      `xml:"title"`
	Link    *AtomLink   `xml:"link"`
	Updated string      `xml:"updated"`
	Summary *AtomText   `xml:"summary"`
	Content *AtomContent `xml:"content"`
}

type AtomText struct {
	Type    string `xml:"type,attr"`
	Content string `xml:",chardata"`
}

type AtomContent struct {
	Type    string `xml:"type,attr"`
	Content string `xml:",chardata"`
}

// JSON Feed structures
type JSONFeed struct {
	Version     string         `json:"version"`
	Title       string         `json:"title"`
	HomePageURL string         `json:"home_page_url"`
	FeedURL     string         `json:"feed_url"`
	Description string         `json:"description"`
	Items       []JSONFeedItem `json:"items"`
}

type JSONFeedItem struct {
	ID            string           `json:"id"`
	URL           string           `json:"url"`
	Title         string           `json:"title"`
	ContentHTML   string           `json:"content_html"`
	ContentText   string           `json:"content_text"`
	DatePublished string           `json:"date_published"`
	DateModified  string           `json:"date_modified"`
	Author        *JSONFeedAuthor  `json:"author"`
}

type JSONFeedAuthor struct {
	Name string `json:"name"`
}

// RSSFeed generates RSS 2.0 feed for the blog
func (h *Handlers) RSSFeed(c echo.Context) error {
	blog := middleware.GetBlog(c)
	if blog == nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Blog not found in context")
	}

	// Get blog owner
	user, err := h.repos.User.FindByID(c.Request().Context(), blog.UserID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load user")
	}

	// Get recent published posts (limit 20)
	posts, err := h.repos.Post.ListPublished(c.Request().Context(), blog.ID, 20, 0)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load posts")
	}

	// Get URL components from request
	protocol := getProtocol(c)
	host := c.Request().Host
	port := getPort(c)

	// Build base URL
	baseURL := protocol + "://" + host

	// Build RSS items
	items := make([]RSSItem, 0, len(posts))
	for _, post := range posts {
		if post.Title == nil || post.Slug == nil || post.BodyMarkdown == nil {
			continue
		}

		// Render markdown to HTML
		bodyHTML, err := markdown.RenderString(*post.BodyMarkdown)
		if err != nil {
			bodyHTML = ""
		}

		// Sanitize HTML for feed
		sanitizedHTML := helpers.SanitizeHTMLForFeed(bodyHTML, protocol, host, port, "/"+*post.Slug)

		item := RSSItem{
			Title:       *post.Title,
			Link:        baseURL + "/" + *post.Slug,
			Description: sanitizedHTML,
			GUID:        baseURL + "/" + *post.Slug,
		}

		if post.PublishedAt != nil {
			item.PubDate = post.PublishedAt.Format(time.RFC1123Z)
		}

		items = append(items, item)
	}

	// Build RSS feed
	userName := getUserName(user)
	rss := RSS{
		Version: "2.0",
		Atom:    "http://www.w3.org/2005/Atom",
		Channel: &Channel{
			Title:       getTitle(blog),
			Link:        baseURL,
			Description: "Latest posts from " + userName,
			Language:    "en",
			AtomLink: &AtomLink{
				Href: baseURL + "/feed.rss",
				Rel:  "self",
				Type: "application/rss+xml",
			},
			Items: items,
		},
	}

	// Set content type and encode XML
	c.Response().Header().Set("Content-Type", "application/rss+xml; charset=utf-8")
	c.Response().WriteHeader(http.StatusOK)

	encoder := xml.NewEncoder(c.Response().Writer)
	encoder.Indent("", "  ")

	// Write XML declaration
	c.Response().Writer.Write([]byte(xml.Header))

	return encoder.Encode(rss)
}

// AtomFeed generates Atom 1.0 feed for the blog
func (h *Handlers) AtomFeed(c echo.Context) error {
	blog := middleware.GetBlog(c)
	if blog == nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Blog not found in context")
	}

	// Get blog owner
	user, err := h.repos.User.FindByID(c.Request().Context(), blog.UserID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load user")
	}

	// Get recent published posts (limit 20)
	posts, err := h.repos.Post.ListPublished(c.Request().Context(), blog.ID, 20, 0)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load posts")
	}

	// Get URL components from request
	protocol := getProtocol(c)
	host := c.Request().Host
	port := getPort(c)

	// Build base URL
	baseURL := protocol + "://" + host

	// Build Atom entries
	entries := make([]AtomEntry, 0, len(posts))
	for _, post := range posts {
		if post.Title == nil || post.Slug == nil || post.BodyMarkdown == nil {
			continue
		}

		// Render markdown to HTML
		bodyHTML, err := markdown.RenderString(*post.BodyMarkdown)
		if err != nil {
			bodyHTML = ""
		}

		// Sanitize HTML for feed
		sanitizedHTML := helpers.SanitizeHTMLForFeed(bodyHTML, protocol, host, port, "/"+*post.Slug)

		// Build summary from meta description or title + author
		userName := getUserName(user)
		summary := ""
		if post.MetaDescription != nil && *post.MetaDescription != "" {
			summary = *post.MetaDescription
		} else {
			summary = *post.Title + " by " + userName
		}

		entry := AtomEntry{
			ID:    baseURL + "/" + *post.Slug,
			Title: *post.Title,
			Link: &AtomLink{
				Href: baseURL + "/" + *post.Slug,
				Rel:  "alternate",
				Type: "text/html",
			},
			Summary: &AtomText{
				Type:    "text",
				Content: summary,
			},
			Content: &AtomContent{
				Type:    "html",
				Content: sanitizedHTML,
			},
		}

		if post.PublishedAt != nil {
			entry.Updated = post.PublishedAt.Format(time.RFC3339)
		}

		entries = append(entries, entry)
	}

	// Get updated timestamp from first post
	updated := time.Now().Format(time.RFC3339)
	if len(posts) > 0 && posts[0].PublishedAt != nil {
		updated = posts[0].PublishedAt.Format(time.RFC3339)
	}

	// Build Atom feed
	userName := getUserName(user)
	feed := AtomFeed{
		Xmlns:    "http://www.w3.org/2005/Atom",
		ID:       baseURL,
		Title:    getTitle(blog),
		Updated:  updated,
		Author:   &AtomAuthor{Name: userName},
		Links: []AtomLink{
			{
				Href: baseURL + "/feed.atom",
				Rel:  "self",
				Type: "application/atom+xml",
			},
			{
				Href: baseURL,
				Rel:  "alternate",
				Type: "text/html",
			},
		},
		Subtitle: "Latest posts from " + userName,
		Entries:  entries,
	}

	// Set content type and encode XML
	c.Response().Header().Set("Content-Type", "application/atom+xml; charset=utf-8")
	c.Response().WriteHeader(http.StatusOK)

	encoder := xml.NewEncoder(c.Response().Writer)
	encoder.Indent("", "  ")

	// Write XML declaration
	c.Response().Writer.Write([]byte(xml.Header))

	return encoder.Encode(feed)
}

// JSONFeed generates JSON Feed 1.1 for the blog
func (h *Handlers) JSONFeed(c echo.Context) error {
	blog := middleware.GetBlog(c)
	if blog == nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Blog not found in context")
	}

	// Get blog owner
	user, err := h.repos.User.FindByID(c.Request().Context(), blog.UserID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load user")
	}

	// Get recent published posts (limit 20)
	posts, err := h.repos.Post.ListPublished(c.Request().Context(), blog.ID, 20, 0)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load posts")
	}

	// Get URL components from request
	protocol := getProtocol(c)
	host := c.Request().Host
	port := getPort(c)

	// Build base URL
	baseURL := protocol + "://" + host

	// Build JSON feed items
	items := make([]JSONFeedItem, 0, len(posts))
	for _, post := range posts {
		if post.Title == nil || post.Slug == nil || post.BodyMarkdown == nil {
			continue
		}

		// Render markdown to HTML
		bodyHTML, err := markdown.RenderString(*post.BodyMarkdown)
		if err != nil {
			bodyHTML = ""
		}

		// Sanitize HTML for feed
		sanitizedHTML := helpers.SanitizeHTMLForFeed(bodyHTML, protocol, host, port, "/"+*post.Slug)

		// Build content_text from meta description or title + author
		userName := getUserName(user)
		contentText := ""
		if post.MetaDescription != nil && *post.MetaDescription != "" {
			contentText = *post.MetaDescription
		} else {
			contentText = *post.Title + " by " + userName
		}

		item := JSONFeedItem{
			ID:          baseURL + "/" + *post.Slug,
			URL:         baseURL + "/" + *post.Slug,
			Title:       *post.Title,
			ContentHTML: sanitizedHTML,
			ContentText: contentText,
			Author:      &JSONFeedAuthor{Name: userName},
		}

		if post.PublishedAt != nil {
			item.DatePublished = post.PublishedAt.Format(time.RFC3339)
		}
		item.DateModified = post.UpdatedAt.Format(time.RFC3339)

		items = append(items, item)
	}

	// Build JSON feed
	userName := getUserName(user)
	feed := JSONFeed{
		Version:     "https://jsonfeed.org/version/1.1",
		Title:       getTitle(blog),
		HomePageURL: baseURL,
		FeedURL:     baseURL + "/feed.json",
		Description: "Latest posts from " + userName,
		Items:       items,
	}

	// Set content type and encode JSON
	c.Response().Header().Set("Content-Type", "application/feed+json; charset=utf-8")
	return c.JSON(http.StatusOK, feed)
}

// Subscribe displays the subscribe page with feed information
func (h *Handlers) Subscribe(c echo.Context) error {
	blog := middleware.GetBlog(c)
	if blog == nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Blog not found in context")
	}

	// Get URL components for feed URLs
	protocol := getProtocol(c)
	host := c.Request().Host
	baseURL := protocol + "://" + host

	data := map[string]interface{}{
		"Blog":        blog,
		"Title":       getTitle(blog) + " - Subscribe",
		"RSSFeedURL":  baseURL + "/feed.rss",
		"AtomFeedURL": baseURL + "/feed.atom",
		"JSONFeedURL": baseURL + "/feed.json",
	}

	return h.renderTemplate(c, "subscribe.html", data)
}

// Helper functions

func getProtocol(c echo.Context) string {
	if c.Request().TLS != nil {
		return "https"
	}
	// Check X-Forwarded-Proto header for proxy scenarios
	if proto := c.Request().Header.Get("X-Forwarded-Proto"); proto != "" {
		return proto
	}
	return "http"
}

func getPort(c echo.Context) int {
	if c.Request().TLS != nil {
		return 443
	}
	// In production behind a proxy, port might not be relevant
	// For local development, we might have a non-standard port
	// But for URL construction, we'll use 0 to indicate standard port
	return 0
}

func getUserName(user *models.User) string {
	if user.Name != nil && *user.Name != "" {
		return *user.Name
	}
	return user.Email
}

func stringOrDefault(s *string, defaultVal string) string {
	if s != nil && *s != "" {
		return *s
	}
	return defaultVal
}
