import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form", "input"]
  static values = { url: String }

  connect() {
    // Ensure we start in display mode
    this.showDisplay()
  }

  edit(event) {
    event.preventDefault()
    this.showForm()
    // Focus the input after a short delay to ensure it's visible
    setTimeout(() => {
      if (this.hasInputTarget) {
        this.inputTarget.focus()
        this.inputTarget.select()
      }
    }, 50)
  }

  save(event) {
    event.preventDefault()
    const form = event.target.closest("form")
    if (form) {
      form.requestSubmit()
    }
  }

  cancel(event) {
    event.preventDefault()
    this.showDisplay()
    // Reset input value to original
    if (this.hasInputTarget && this.hasDisplayTarget) {
      this.inputTarget.value = this.displayTarget.textContent.trim()
    }
  }

  handleKeydown(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.save(event)
    } else if (event.key === "Escape") {
      event.preventDefault()
      this.cancel(event)
    }
  }

  handleBlur(event) {
    // Small delay to allow clicking save/cancel buttons
    setTimeout(() => {
      if (this.formTarget.contains(document.activeElement)) {
        return // Focus is still within the form
      }
      this.save(event)
    }, 150)
  }

  showDisplay() {
    if (this.hasDisplayTarget) {
      this.displayTarget.hidden = false
    }
    if (this.hasFormTarget) {
      this.formTarget.hidden = true
    }
  }

  showForm() {
    if (this.hasDisplayTarget) {
      this.displayTarget.hidden = true
    }
    if (this.hasFormTarget) {
      this.formTarget.hidden = false
    }
  }
}