import { Controller } from "@hotwired/stimulus"

// Usage: data-controller="theme" on <html> or <body>
// Call theme#setTheme via data-action on a select input to update the theme live
export default class extends Controller {
  static values = { default: String }
  static targets = ["select"]

  connect() {
    // Set initial theme from value or data-theme attribute
    const theme = this.defaultValue || document.documentElement.dataset.theme || "tokyo"
    this.setTheme(theme)
  }

  setTheme(eventOrTheme) {
    let theme
    if (typeof eventOrTheme === "string") {
      theme = eventOrTheme
    } else if (eventOrTheme && eventOrTheme.target) {
      theme = eventOrTheme.target.value
    } else {
      theme = this.defaultValue || "tokyo"
    }
    if (!theme) return
    document.documentElement.setAttribute("data-theme", theme)
  }
}