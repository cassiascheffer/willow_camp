import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hiddenField", "dropdownButton", "buttonPreview", "buttonText"]

  selectTheme(event) {
    const button = event.currentTarget
    const theme = button.dataset.themeValue

    // Update hidden field
    this.hiddenFieldTarget.value = theme

    // Update dropdown button
    this.buttonPreviewTarget.setAttribute('data-theme', theme)
    this.buttonTextTarget.textContent = theme



    // Update checkmarks
    this.clearCheckmarks()
    this.addCheckmarkTo(button)

    // Close dropdown
    this.dropdownButtonTarget.blur()

    // Apply theme immediately for preview
    document.documentElement.setAttribute('data-theme', theme)

    // Auto-submit the form with Turbo
    this.element.closest('form').requestSubmit()
  }

  clearCheckmarks() {
    this.element.querySelectorAll('.theme-option svg').forEach(svg => svg.remove())
  }

  addCheckmarkTo(button) {
    const checkmark = this.createCheckmarkSVG()
    button.appendChild(checkmark)
  }

  createCheckmarkSVG() {
    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
    svg.setAttribute('class', 'w-4 h-4 text-primary')
    svg.setAttribute('fill', 'currentColor')
    svg.setAttribute('viewBox', '0 0 20 20')
    svg.innerHTML = '<path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>'
    return svg
  }
}
