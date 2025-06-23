import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "form"]
  static values = {
    interval: { type: Number, default: 10000 }
  }

  connect() {
    this.isSubmitting = false
    this.isAutoSaving = false
    this.abortAutoSave = false
    this.bindEventHandlers()
    this.attachEventListeners()
    this.startAutoSave()
    this.setStatus("Auto-save enabled")
  }

  disconnect() {
    this.stopAutoSave()
    this.removeEventListeners()
  }

  // Event handler binding (fixes memory leak issue)
  bindEventHandlers() {
    this.boundSubmitStart = this.handleSubmitStart.bind(this)
    this.boundSubmitEnd = this.handleSubmitEnd.bind(this)
    this.boundKeydown = this.handleKeydown.bind(this)
    this.boundPublishedChange = this.handlePublishedChange.bind(this)
  }

  attachEventListeners() {
    this.formTarget.addEventListener("turbo:submit-start", this.boundSubmitStart)
    this.formTarget.addEventListener("turbo:submit-end", this.boundSubmitEnd)
    document.addEventListener("keydown", this.boundKeydown)

    const publishedInput = this.publishedInput
    if (publishedInput) {
      publishedInput.addEventListener("change", this.boundPublishedChange)
    }
  }

  removeEventListeners() {
    this.formTarget.removeEventListener("turbo:submit-start", this.boundSubmitStart)
    this.formTarget.removeEventListener("turbo:submit-end", this.boundSubmitEnd)
    document.removeEventListener("keydown", this.boundKeydown)

    const publishedInput = this.publishedInput
    if (publishedInput) {
      publishedInput.removeEventListener("change", this.boundPublishedChange)
    }
  }

  // Auto-save management
  startAutoSave() {
    this.clearTimer('autoSaveTimer')
    this.autoSaveTimer = setInterval(() => this.performAutoSave(), this.intervalValue)
  }

  stopAutoSave() {
    this.clearTimer('autoSaveTimer')
  }

  performAutoSave() {
    if (this.isSubmitting) return

    if (this.isPublished) {
      this.setStatus("Auto-save disabled (published post)")
      return
    }

    this.isAutoSaving = true
    this.abortAutoSave = false
    this.setStatus("Saving...")
    this.formTarget.requestSubmit()
  }

  // Manual save (Cmd+S / Ctrl+S)
  manualSave(event = null) {
    event?.preventDefault()

    this.stopAutoSave()
    this.setStatus("Saving...")
    this.formTarget.requestSubmit()

    // Restart auto-save after brief delay
    setTimeout(() => this.startAutoSave(), 1000)
  }

  // Event handlers
  handleKeydown(event) {
    if ((event.metaKey || event.ctrlKey) && event.key === 's') {
      event.preventDefault()
      this.manualSave()
    }
  }

  handleSubmitStart() {
    this.isSubmitting = true
  }

  handleSubmitEnd(event) {
    this.isSubmitting = false
    const wasAutoSaving = this.isAutoSaving
    this.isAutoSaving = false

    // If auto-save was aborted due to published state change, ignore the result
    if (wasAutoSaving && this.abortAutoSave) {
      this.abortAutoSave = false
      this.setStatus("Auto-save cancelled - Published state changed")
      return
    }

    if (event.detail.success) {
      if (this.isPublished) {
        this.stopAutoSave()
        this.setStatus("Saved - Auto-save disabled (published)", "success")
      } else {
        this.setStatus("Saved", "success")
        this.setStatusWithDelay("Auto-save enabled", 3000)
      }
    } else {
      this.setStatus("Save failed", "error")
      this.setStatusWithDelay("Auto-save enabled", 5000)
    }
  }

  handlePublishedChange(event) {
    // If auto-save is currently in progress, mark it for abortion
    if (this.isAutoSaving) {
      this.abortAutoSave = true
    }

    if (event.target.checked) {
      this.stopAutoSave()
      this.setStatus("Auto-save disabled (manual save only)")
    } else {
      this.startAutoSave()
      this.setStatus("Auto-save re-enabled")
    }
  }

  // Helper methods
  get publishedInput() {
    return this.formTarget.querySelector('input[name*="[published]"][type="checkbox"]')
  }

  get isPublished() {
    return this.publishedInput?.checked || false
  }

  setStatus(message, type = "default") {
    if (!this.hasStatusTarget) return

    this.statusTarget.textContent = message
    this.statusTarget.className = this.getStatusClass(type)
  }

  setStatusWithDelay(message, delay) {
    this.clearTimer('statusTimeout')
    this.statusTimeout = setTimeout(() => this.setStatus(message), delay)
  }

  getStatusClass(type) {
    const baseClass = "text-sm mt-2"
    const typeClasses = {
      success: "text-green-600",
      error: "text-red-600",
      default: "text-gray-600"
    }
    return `${baseClass} ${typeClasses[type] || typeClasses.default}`
  }

  clearTimer(timerName) {
    if (this[timerName]) {
      clearInterval(this[timerName])
      clearTimeout(this[timerName])
      this[timerName] = null
    }
  }
}
