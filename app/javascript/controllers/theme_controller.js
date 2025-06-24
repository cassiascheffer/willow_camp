import { Controller } from "@hotwired/stimulus"

// Core theme management controller for automatic light/dark theme switching
// Handles browser preference detection and theme application without UI components
export default class extends Controller {
  static values = {
    lightTheme: String,
    darkTheme: String
  }

  connect() {
    this.setTransitionSpeed('normal')
    this.initializeTheme()
    this.setupMediaQueryListener()
  }

  disconnect() {
    if (this.mediaQueryListener) {
      this.mediaQuery.removeEventListener('change', this.mediaQueryListener)
    }
  }

  // Initialize theme on page load - only apply if user has custom preferences and not already set
  initializeTheme() {
    // Only override daisyUI's automatic theme if user has custom preferences
    if (this.hasCustomThemes() && !this.isThemeAlreadyCorrect()) {
      this.applyCurrentTheme('normal')
    }
  }

  // Apply current theme based on browser preference
  applyCurrentTheme(speed = 'normal') {
    const theme = this.getCurrentTheme()
    if (theme) {
      this.applyTheme(theme, speed)
    }
  }

  // Check if user has custom theme preferences (not default light/dark)
  hasCustomThemes() {
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
    const expectedDefault = prefersDark ? 'dark' : 'light'
    const currentTheme = this.getCurrentTheme()

    return currentTheme && currentTheme !== expectedDefault
  }

  // Apply specific theme with transition control
  applyTheme(theme, speed = 'normal') {
    this.setTransitionSpeed(speed)
    document.documentElement.setAttribute("data-theme", theme)
  }

  // External API for updating theme values
  updateThemeValues(lightTheme, darkTheme) {
    this.lightThemeValue = lightTheme
    this.darkThemeValue = darkTheme
    this.applyCurrentTheme()
  }

  // Get current theme based on browser preference
  getCurrentTheme() {
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
    return prefersDark ? this.darkThemeValue : this.lightThemeValue
  }

  // Control CSS transition speed
  setTransitionSpeed(speed) {
    const duration = speed === 'fast' ? '0.15s' : '0.3s'
    document.documentElement.style.setProperty('--theme-transition-duration', duration)
  }

  // Check if the current theme is already correctly applied
  isThemeAlreadyCorrect() {
    const currentDataTheme = document.documentElement.getAttribute('data-theme')
    const expectedTheme = this.getCurrentTheme()
    return currentDataTheme === expectedTheme
  }

  // Set up listener for browser color scheme changes
  setupMediaQueryListener() {
    this.mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
    this.mediaQueryListener = () => this.applyCurrentTheme()
    this.mediaQuery.addEventListener('change', this.mediaQueryListener)
  }
}
