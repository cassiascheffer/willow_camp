import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { theme: String }

  connect() {
    this.updateTheme()
    this.addTurboEventListeners()
  }

  disconnect() {
    this.removeTurboEventListeners()
  }

  themeValueChanged() {
    this.updateTheme()
  }

  addTurboEventListeners() {
    this.turboLoadHandler = this.handleTurboLoad.bind(this)
    this.turboRenderHandler = this.handleTurboRender.bind(this)
    this.turboVisitHandler = this.handleTurboVisit.bind(this)

    document.addEventListener('turbo:load', this.turboLoadHandler)
    document.addEventListener('turbo:render', this.turboRenderHandler)
    document.addEventListener('turbo:visit', this.turboVisitHandler)
  }

  removeTurboEventListeners() {
    if (this.turboLoadHandler) {
      document.removeEventListener('turbo:load', this.turboLoadHandler)
    }
    if (this.turboRenderHandler) {
      document.removeEventListener('turbo:render', this.turboRenderHandler)
    }
    if (this.turboVisitHandler) {
      document.removeEventListener('turbo:visit', this.turboVisitHandler)
    }
  }

  handleTurboLoad() {
    this.updateTheme()
  }

  handleTurboRender() {
    this.updateTheme()
  }

  handleTurboVisit() {
    this.updateTheme()
  }

  updateTheme() {
    // Use the theme value if available, otherwise fall back to default
    const theme = this.themeValue || 'light'
    document.documentElement.setAttribute('data-theme', theme)
  }
}
