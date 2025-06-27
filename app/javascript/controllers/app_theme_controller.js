import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview", "text"]

  connect() {
    // Set initial theme from localStorage or system preference
    this.setInitialTheme()
    // Update preview elements with saved values
    this.updatePreviewElements()
  }

  setInitialTheme() {
    const savedTheme = localStorage.getItem('theme')
    let theme = savedTheme

    if (!theme) {
      // Fall back to system preference
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
      theme = prefersDark ? 'dark' : 'light'
    }

    this.applyTheme(theme)
  }

  selectTheme(event) {
    const theme = event.currentTarget.dataset.themeValue

    // Update preview and text if targets exist
    if (this.hasPreviewTarget) {
      this.previewTarget.setAttribute('data-theme', theme)
    }
    if (this.hasTextTarget) {
      this.textTarget.textContent = theme
    }

    this.applyTheme(theme)

    // Store in localStorage for persistence
    localStorage.setItem('theme', theme)

    // Close dropdown if it exists
    const dropdown = event.currentTarget.closest('.dropdown')
    if (dropdown) {
      dropdown.querySelector('[tabindex="0"]')?.blur()
    }
  }

  applyTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme)
  }

  updatePreviewElements() {
    const savedTheme = localStorage.getItem('theme') || 'light'

    // Update preview and text if targets exist
    if (this.hasPreviewTarget) {
      this.previewTarget.setAttribute('data-theme', savedTheme)
    }
    if (this.hasTextTarget) {
      this.textTarget.textContent = savedTheme
    }
  }


}
