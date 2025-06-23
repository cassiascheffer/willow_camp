import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "form"]
  static values = {
    interval: { type: Number, default: 10000 }
  }

  connect() {
    this.startAutoSave()
    this.updateStatus("Auto-save enabled")
    this.bindEvents()
  }

  disconnect() {
    this.stopAutoSave()
    this.unbindEvents()
  }

  bindEvents() {
    // Listen for Turbo form events
    this.formTarget.addEventListener("turbo:submit-start", this.handleSubmitStart.bind(this))
    this.formTarget.addEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))

    // Listen for keyboard shortcuts
    document.addEventListener("keydown", this.handleKeydown.bind(this))

    // Listen for published checkbox changes
    const publishedInput = this.getPublishedInput()
    if (publishedInput) {
      publishedInput.addEventListener("change", this.handlePublishedChange.bind(this))
    }
  }

  unbindEvents() {
    this.formTarget.removeEventListener("turbo:submit-start", this.handleSubmitStart.bind(this))
    this.formTarget.removeEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))
    document.removeEventListener("keydown", this.handleKeydown.bind(this))

    // Remove published checkbox listener
    const publishedInput = this.getPublishedInput()
    if (publishedInput) {
      publishedInput.removeEventListener("change", this.handlePublishedChange.bind(this))
    }
  }

  startAutoSave() {
    this.stopAutoSave() // Ensure no duplicate timers
    this.autoSaveTimer = setInterval(() => {
      this.performAutoSave()
    }, this.intervalValue)
  }

  stopAutoSave() {
    if (this.autoSaveTimer) {
      clearInterval(this.autoSaveTimer)
      this.autoSaveTimer = null
    }
  }

  performAutoSave() {
    // Don't auto-save if form is currently being submitted
    if (this.isSubmitting) return

    // Don't auto-save published posts
    if (this.isPostPublished()) {
      this.updateStatus("Auto-save disabled (published post)")
      return
    }

    this.updateStatus("Saving...")

    // Let Turbo handle the form submission naturally
    this.formTarget.requestSubmit()
  }

  manualSave(event = null) {
    event?.preventDefault()
    // Temporarily stop auto-save during manual save
    this.stopAutoSave()

    this.updateStatus("Saving...")

    // Let Turbo handle the form submission naturally
    this.formTarget.requestSubmit()

    // Restart auto-save after a brief delay
    setTimeout(() => {
      this.startAutoSave()
    }, 1000)
  }

  handleKeydown(event) {
    // Handle Cmd+S (Mac) or Ctrl+S (Windows/Linux)
    if ((event.metaKey || event.ctrlKey) && event.key === 's') {
      event.preventDefault()
      this.manualSave()
    }
  }

  handleSubmitStart(event) {
    this.isSubmitting = true
  }

  handleSubmitEnd(event) {
    this.isSubmitting = false

    if (event.detail.success) {
      // Check if post was just published
      if (this.isPostPublished()) {
        this.stopAutoSave()
        this.updateStatus("Saved - Auto-save disabled (published)", "success")
      } else {
        this.updateStatus("Saved", "success")
        this.clearStatusAfterDelay(3000, "Auto-save enabled")
      }
    } else {
      this.updateStatus("Save failed", "error")
      this.clearStatusAfterDelay(5000, "Auto-save enabled")
    }
  }

  handlePublishedChange(event) {
    if (event.target.checked) {
      // User just checked the published checkbox - stop auto-save immediately
      this.stopAutoSave()
      this.updateStatus("Auto-save disabled (manual save only)")
    } else {
      // User unchecked the published checkbox - re-enable auto-save
      if (!this.autoSaveTimer) {
        this.startAutoSave()
        this.updateStatus("Auto-save re-enabled")
      }
    }
  }

  // Helper methods

  getPublishedInput() {
    return this.formTarget.querySelector('input[name*="[published]"][type="checkbox"]')
  }

  isPostPublished() {
    const publishedInput = this.getPublishedInput()
    return publishedInput?.checked || false
  }

  updateStatus(message, type = "default") {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
      this.statusTarget.className = this.getStatusClass(type)
    }
  }

  getStatusClass(type) {
    const baseClass = "text-sm mt-2"
    switch (type) {
      case "success":
        return `${baseClass} text-green-600`
      case "error":
        return `${baseClass} text-red-600`
      default:
        return `${baseClass} text-gray-600`
    }
  }

  clearStatusAfterDelay(delay, message) {
    if (this.statusTimeout) {
      clearTimeout(this.statusTimeout)
    }

    this.statusTimeout = setTimeout(() => {
      this.updateStatus(message)
    }, delay)
  }
}
