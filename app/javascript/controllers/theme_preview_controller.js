import { Controller } from "@hotwired/stimulus"

// Usage: 
// 1. Add data-controller="theme-preview" to the theme <select> input
// 2. Add data-action="change->theme-preview#updateTheme" to the same input
// This will update the data-theme attribute on <html> for live preview

export default class extends Controller {
  updateTheme(event) {
    const theme = event.target.value
    if (theme) {
      document.documentElement.setAttribute("data-theme", theme)
    }
  }
}