import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status"]
  static values = {
    interval: { type: Number, default: 10000 } // 10 seconds
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
    this.element.addEventListener("turbo:submit-start", this.handleSubmitStart.bind(this))
    this.element.addEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))

    // Listen for keyboard shortcuts
    document.addEventListener("keydown", this.handleKeydown.bind(this))
  }

  unbindEvents() {
    this.element.removeEventListener("turbo:submit-start", this.handleSubmitStart.bind(this))
    this.element.removeEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))
    document.removeEventListener("keydown", this.handleKeydown.bind(this))
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

    // Auto-fill title if blank
    this.ensureTitleExists()

    // Ensure post is saved as draft
    this.ensureDraftStatus()

    this.updateStatus("Auto-saving...")
    this.addAutoSaveMarker()

    // Let Turbo handle the form submission naturally
    this.element.requestSubmit()
  }

  manualSave(event) {
    event?.preventDefault()

    // Temporarily stop auto-save during manual save
    this.stopAutoSave()

    this.updateStatus("Saving...")
    this.addManualSaveMarker()

    // Let Turbo handle the form submission naturally
    this.element.requestSubmit()

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

    const wasAutoSave = this.hasAutoSaveMarker()
    const wasManualSave = this.hasManualSaveMarker()

    // Clean up markers
    this.removeMarkers()

    if (event.detail.success) {
      this.handleSuccessfulSave(wasAutoSave, wasManualSave)
    } else {
      this.handleFailedSave(wasAutoSave, wasManualSave)
    }
  }

  handleSuccessfulSave(wasAutoSave, wasManualSave) {
    if (wasAutoSave) {
      this.updateStatus("Auto-saved", "success")
      this.clearStatusAfterDelay(3000, "Auto-save enabled")
    } else if (wasManualSave) {
      this.updateStatus("Saved", "success")
      this.clearStatusAfterDelay(3000, "Auto-save enabled")
    }
  }

  handleFailedSave(wasAutoSave, wasManualSave) {
    if (wasAutoSave) {
      this.updateStatus("Auto-save failed", "error")
      this.clearStatusAfterDelay(5000, "Auto-save enabled")
    } else if (wasManualSave) {
      this.updateStatus("Save failed", "error")
      this.clearStatusAfterDelay(5000, "Auto-save enabled")
    }
  }

  // Helper methods
  isPostPublished() {
    const publishedInput = this.element.querySelector('input[name*="[published]"][type="checkbox"]')
    return publishedInput?.checked || false
  }

  ensureTitleExists() {
    const titleInput = this.element.querySelector('input[name*="[title]"]')
    if (titleInput && !titleInput.value.trim()) {
      titleInput.value = "Untitled"
    }
  }

  ensureDraftStatus() {
    const publishedInput = this.element.querySelector('input[name*="[published]"][type="checkbox"]')
    if (publishedInput) {
      publishedInput.checked = false
    }
  }

  addAutoSaveMarker() {
    this.removeMarkers()
    const marker = this.createHiddenInput('auto_save', 'true')
    this.element.appendChild(marker)
  }

  addManualSaveMarker() {
    this.removeMarkers()
    const marker = this.createHiddenInput('manual_save', 'true')
    this.element.appendChild(marker)
  }

  removeMarkers() {
    const autoSaveMarker = this.element.querySelector('input[name="auto_save"]')
    const manualSaveMarker = this.element.querySelector('input[name="manual_save"]')

    if (autoSaveMarker) autoSaveMarker.remove()
    if (manualSaveMarker) manualSaveMarker.remove()
  }

  hasAutoSaveMarker() {
    return !!this.element.querySelector('input[name="auto_save"]')
  }

  hasManualSaveMarker() {
    return !!this.element.querySelector('input[name="manual_save"]')
  }

  createHiddenInput(name, value) {
    const input = document.createElement('input')
    input.type = 'hidden'
    input.name = name
    input.value = value
    return input
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
