// ABOUTME: Controller to manage theme switching and persistence across Turbo navigation
// ABOUTME: Handles theme application from server data and sessionStorage for seamless UX

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { theme: String }

  connect() {
    this.applyTheme()
    this.addTurboEventListeners()
  }

  disconnect() {
    this.removeTurboEventListeners()
  }

  themeValueChanged() {
    this.applyTheme()
  }

  addTurboEventListeners() {
    this.turboBeforeRenderHandler = this.handleTurboBeforeRender.bind(this)
    this.turboLoadHandler = this.handleTurboLoad.bind(this)
    this.turboRenderHandler = this.handleTurboRender.bind(this)

    document.addEventListener('turbo:before-render', this.turboBeforeRenderHandler)
    document.addEventListener('turbo:load', this.turboLoadHandler)
    document.addEventListener('turbo:render', this.turboRenderHandler)
  }

  removeTurboEventListeners() {
    if (this.turboBeforeRenderHandler) {
      document.removeEventListener('turbo:before-render', this.turboBeforeRenderHandler)
    }
    if (this.turboLoadHandler) {
      document.removeEventListener('turbo:load', this.turboLoadHandler)
    }
    if (this.turboRenderHandler) {
      document.removeEventListener('turbo:render', this.turboRenderHandler)
    }
  }

  handleTurboBeforeRender(event) {
    this.applyThemeFromMeta()
  }

  handleTurboLoad() {
    this.applyTheme()
  }

  handleTurboRender() {
    this.applyTheme()
  }

  applyTheme() {
    const theme = this.getEffectiveTheme()
    this.setTheme(theme)
    
    if (this.themeValue) {
      sessionStorage.setItem('current-theme', theme)
    }
  }

  applyThemeFromMeta() {
    const metaTheme = document.querySelector('meta[name="current-theme"]')?.getAttribute('content')
    const storedTheme = sessionStorage.getItem('current-theme')
    const theme = storedTheme || metaTheme || 'light'
    this.setTheme(theme)
  }

  getEffectiveTheme() {
    if (this.themeValue) {
      return this.themeValue
    }
    
    const storedTheme = sessionStorage.getItem('current-theme')
    if (storedTheme) {
      return storedTheme
    }
    
    const metaTheme = document.querySelector('meta[name="current-theme"]')?.getAttribute('content')
    return metaTheme || 'light'
  }

  setTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme)
  }
}