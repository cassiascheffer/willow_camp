package helpers

// AllThemes returns all available DaisyUI themes
// Matches Rails: ALL_THEMES constant in app/helpers/application_helper.rb
func AllThemes() []string {
	return []string{
		"light", "dark", "abyss", "acid", "aqua", "autumn", "black", "bumblebee",
		"business", "caramellatte", "cmyk", "coffee", "corporate", "cupcake",
		"cyberpunk", "dim", "dracula", "emerald", "fantasy", "forest", "garden",
		"halloween", "lemonade", "lofi", "luxury", "night", "nord", "pastel",
		"retro", "silk", "sunset", "synthwave", "valentine", "vineframe", "winter",
	}
}
