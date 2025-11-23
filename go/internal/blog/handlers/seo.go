package handlers

import (
	"encoding/xml"
	"net/http"

	"github.com/cassiascheffer/willow_camp/internal/blog/middleware"
	"github.com/labstack/echo/v4"
)

type URLSet struct {
	XMLName xml.Name `xml:"urlset"`
	XMLNS   string   `xml:"xmlns,attr"`
	URLs    []URL    `xml:"url"`
}

type URL struct {
	Loc        string `xml:"loc"`
	LastMod    string `xml:"lastmod,omitempty"`
	ChangeFreq string `xml:"changefreq,omitempty"`
	Priority   string `xml:"priority,omitempty"`
}

// Sitemap generates XML sitemap
func (h *Handlers) Sitemap(c echo.Context) error {
	blog := middleware.GetBlog(c)
	if blog == nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Blog not found in context")
	}

	scheme := "http"
	if c.Request().TLS != nil {
		scheme = "https"
	}
	baseURL := scheme + "://" + c.Request().Host

	urls := []URL{
		{
			Loc:        baseURL + "/",
			ChangeFreq: "daily",
			Priority:   "1.0",
		},
		{
			Loc:        baseURL + "/tags",
			ChangeFreq: "weekly",
			Priority:   "0.8",
		},
	}

	// Add all published posts
	posts, err := h.repos.Post.ListPublished(c.Request().Context(), blog.ID, 1000, 0)
	if err == nil {
		for _, post := range posts {
			if post.Slug == nil {
				continue
			}

			url := URL{
				Loc:        baseURL + "/" + *post.Slug,
				ChangeFreq: "weekly",
				Priority:   "0.7",
			}

			if post.UpdatedAt.Year() > 1 {
				url.LastMod = post.UpdatedAt.Format("2006-01-02")
			}

			urls = append(urls, url)
		}
	}

	urlset := URLSet{
		XMLNS: "http://www.sitemaps.org/schemas/sitemap/0.9",
		URLs:  urls,
	}

	c.Response().Header().Set("Content-Type", "application/xml; charset=utf-8")
	c.Response().WriteHeader(http.StatusOK)

	encoder := xml.NewEncoder(c.Response().Writer)
	encoder.Indent("", "  ")

	c.Response().Writer.Write([]byte(xml.Header))
	return encoder.Encode(urlset)
}

// RobotsTxt generates robots.txt
func (h *Handlers) RobotsTxt(c echo.Context) error {
	blog := middleware.GetBlog(c)
	if blog == nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Blog not found in context")
	}

	scheme := "http"
	if c.Request().TLS != nil {
		scheme = "https"
	}
	baseURL := scheme + "://" + c.Request().Host

	robots := "User-agent: *\n"

	if blog.NoIndex {
		robots += "Disallow: /\n"
	} else {
		robots += "Allow: /\n"
		robots += "\nSitemap: " + baseURL + "/sitemap.xml\n"
	}

	c.Response().Header().Set("Content-Type", "text/plain; charset=utf-8")
	return c.String(http.StatusOK, robots)
}
