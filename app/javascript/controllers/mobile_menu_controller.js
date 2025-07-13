import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["summary", "nav"]

  connect() {
    // Add event listener for summary click to update aria-expanded
    this.summaryTarget.addEventListener("click", this.handleToggle.bind(this))

    // Handle keyboard navigation
    this.summaryTarget.addEventListener("keydown", this.handleKeydown.bind(this))

    // Close menu when clicking outside
    document.addEventListener("click", this.handleOutsideClick.bind(this))

    // Initialize aria-expanded state
    this.summaryTarget.setAttribute("aria-expanded", "false")
  }

  disconnect() {
    document.removeEventListener("click", this.handleOutsideClick.bind(this))
  }

  handleToggle() {
    // Use setTimeout to ensure details element state has updated
    setTimeout(() => {
      const isOpen = this.element.open
      this.summaryTarget.setAttribute("aria-expanded", isOpen.toString())

      // Update title text in SVG
      const svg = this.summaryTarget.querySelector("svg title")
      if (svg) {
        svg.textContent = isOpen ? "Close menu" : "Open menu"
      }

      // Focus management
      if (isOpen) {
        // Focus first nav item when menu opens
        const firstNavItem = this.navTarget.querySelector("a")
        if (firstNavItem) {
          firstNavItem.focus()
        }
      }
    }, 0)
  }

  handleKeydown(event) {
    // Handle Escape key to close menu
    if (event.key === "Escape" && this.element.open) {
      this.element.open = false
      this.summaryTarget.setAttribute("aria-expanded", "false")
      this.summaryTarget.focus()
    }

    // Handle Enter and Space keys on summary
    if ((event.key === "Enter" || event.key === " ") && event.target === this.summaryTarget) {
      event.preventDefault()
      this.element.open = !this.element.open
      this.handleToggle()
    }
  }

  handleOutsideClick(event) {
    // Close menu when clicking outside
    if (!this.element.contains(event.target) && this.element.open) {
      this.element.open = false
      this.summaryTarget.setAttribute("aria-expanded", "false")
    }
  }
}
