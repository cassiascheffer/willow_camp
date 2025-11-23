package handlers

import (
	"encoding/xml"
	"net/http"
	"time"

	"github.com/cassiascheffer/willow_camp/internal/blog/middleware"
	"github.com/labstack/echo/v4"
)

type RSS struct {
	XMLName xml.Name `xml:"rss"`
	Version string   `xml:"version,attr"`
	Channel *Channel `xml:"channel"`
}

type Channel struct {
	Title       string `xml:"title"`
	Link        string `xml:"link"`
	Description string `xml:"description"`
	Items       []Item `xml:"item"`
}

type Item struct {
	Title       string `xml:"title"`
	Link        string `xml:"link"`
	Description string `xml:"description"`
	PubDate     string `xml:"pubDate"`
	GUID        string `xml:"guid"`
}

// RSSFeed generates RSS feed for the blog
func (h *Handlers) RSSFeed(c echo.Context) error {
	blog := middleware.GetBlog(c)
	if blog == nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Blog not found in context")
	}

	// Get recent published posts (limit 20)
	posts, err := h.repos.Post.ListPublished(c.Request().Context(), blog.ID, 20, 0)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to load posts")
	}

	// Build RSS items
	items := make([]Item, 0, len(posts))
	for _, post := range posts {
		if post.Title == nil || post.Slug == nil {
			continue
		}

		// Get base URL from request
		scheme := "http"
		if c.Request().TLS != nil {
			scheme = "https"
		}
		baseURL := scheme + "://" + c.Request().Host

		item := Item{
			Title:    *post.Title,
			Link:     baseURL + "/" + *post.Slug,
			GUID:     baseURL + "/" + *post.Slug,
		}

		if post.MetaDescription != nil {
			item.Description = *post.MetaDescription
		} else if post.BodyMarkdown != nil && len(*post.BodyMarkdown) > 200 {
			item.Description = (*post.BodyMarkdown)[:200] + "..."
		}

		if post.PublishedAt != nil {
			item.PubDate = post.PublishedAt.Format(time.RFC1123Z)
		}

		items = append(items, item)
	}

	// Build RSS feed
	rss := RSS{
		Version: "2.0",
		Channel: &Channel{
			Title:       getTitle(blog),
			Link:        "http://" + c.Request().Host,
			Description: stringOrDefault(blog.MetaDescription, "Latest posts from "+getTitle(blog)),
			Items:       items,
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

func stringOrDefault(s *string, defaultVal string) string {
	if s != nil && *s != "" {
		return *s
	}
	return defaultVal
}
