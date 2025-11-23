package handlers

import (
	"net/http"

	"github.com/labstack/echo/v4"
)

// All DaisyUI themes
var allThemes = []string{
	"light", "dark", "abyss", "acid", "aqua", "autumn", "black", "bumblebee",
	"business", "caramellatte", "cmyk", "coffee", "corporate", "cupcake",
	"cyberpunk", "dim", "dracula", "emerald", "fantasy", "forest", "garden",
	"halloween", "lemonade", "lofi", "luxury", "night", "nord", "pastel",
	"retro", "silk", "sunset", "synthwave", "valentine", "vineframe", "winter",
}

// Emoji options for favicon selector
type EmojiOption struct {
	Emoji string
	Code  string
}

var emojiOptions = []EmojiOption{
	{Emoji: "🏕️", Code: "1F3D5"},
	{Emoji: "🌲", Code: "1F332"},
	{Emoji: "🌊", Code: "1F30A"},
	{Emoji: "🌸", Code: "1F338"},
	{Emoji: "🌿", Code: "1F33F"},
	{Emoji: "🍄", Code: "1F344"},
	{Emoji: "🦋", Code: "1F98B"},
	{Emoji: "🌻", Code: "1F33B"},
	{Emoji: "🌙", Code: "1F319"},
	{Emoji: "⛺", Code: "26FA"},
}

// HomePage shows the landing page or redirects to dashboard if logged in
func (h *Handlers) HomePage(c echo.Context) error {
	// Check if user is logged in
	user, err := h.auth.GetCurrentUser(c)
	if err == nil && user != nil {
		// User is logged in, redirect to dashboard
		return c.Redirect(http.StatusFound, "/dashboard")
	}

	// User is not logged in, show home page
	data := map[string]interface{}{
		"Title":    "willow.camp - A blogging platform",
		"Themes":   allThemes,
		"Emojis":   emojiOptions,
		"ShowLogo": false, // Don't show logo in navbar on home page
	}

	return renderApplicationTemplate(c, "home.html", data)
}
