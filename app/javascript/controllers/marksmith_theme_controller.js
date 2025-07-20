import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["wrapper"]

  connect() {
    this.updateMarksmithTheme()
    this.addTurboEventListeners()
  }

  disconnect() {
    this.removeTurboEventListeners()
  }

  addTurboEventListeners() {
    this.turboLoadHandler = this.handleTurboLoad.bind(this)
    this.turboRenderHandler = this.handleTurboRender.bind(this)

    document.addEventListener('turbo:load', this.turboLoadHandler)
    document.addEventListener('turbo:render', this.turboRenderHandler)
  }

  removeTurboEventListeners() {
    if (this.turboLoadHandler) {
      document.removeEventListener('turbo:load', this.turboLoadHandler)
    }
    if (this.turboRenderHandler) {
      document.removeEventListener('turbo:render', this.turboRenderHandler)
    }
  }

  handleTurboLoad() {
    this.updateMarksmithTheme()
  }

  handleTurboRender() {
    this.updateMarksmithTheme()
  }

  updateMarksmithTheme() {
    const currentTheme = document.documentElement.getAttribute('data-theme')
    const darkThemes = [
      'dark', 'synthwave', 'halloween', 'forest', 'black', 
      'luxury', 'dracula', 'business', 'night', 'coffee', 
      'dim', 'sunset', 'abyss'
    ]
    
    const isDarkTheme = darkThemes.includes(currentTheme)
    
    this.wrapperTargets.forEach(wrapper => {
      if (isDarkTheme) {
        wrapper.classList.add('dark')
      } else {
        wrapper.classList.remove('dark')
      }
    })
  }
}