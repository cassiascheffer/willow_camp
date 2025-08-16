import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "statusContainer", "form"]
  static values = {
    interval: { type: Number, default: 60000 }
  }

  connect() {
    this.isSubmitting = false
    this.isAutoSaving = false
    this.abortAutoSave = false
    this.formDirty = false
    this.autoSaveRunning = false
    this.scrollPositions = new Map()
    this.bindEventHandlers()
    this.attachEventListeners()
    // Autosave disabled - only manual save (Cmd/Ctrl+S) works
    // this.startAutoSave()
    this.setStatus("Autosave temporarily disabled. Use command+s to save.", "warning")
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
    this.boundFormInput = this.handleFormInput.bind(this)
    this.boundBeforeStreamRender = this.handleBeforeStreamRender.bind(this)
    this.boundAfterStreamRender = this.handleAfterStreamRender.bind(this)
  }

  attachEventListeners() {
    this.formTarget.addEventListener("turbo:submit-start", this.boundSubmitStart)
    this.formTarget.addEventListener("turbo:submit-end", this.boundSubmitEnd)
    this.formTarget.addEventListener("input", this.boundFormInput)
    document.addEventListener("keydown", this.boundKeydown)
    document.addEventListener("turbo:before-stream-render", this.boundBeforeStreamRender)
    document.addEventListener("turbo:after-stream-render", this.boundAfterStreamRender)

    const publishedInput = this.publishedInput
    if (publishedInput) {
      publishedInput.addEventListener("change", this.boundPublishedChange)
    }
  }

  removeEventListeners() {
    this.formTarget.removeEventListener("turbo:submit-start", this.boundSubmitStart)
    this.formTarget.removeEventListener("turbo:submit-end", this.boundSubmitEnd)
    this.formTarget.removeEventListener("input", this.boundFormInput)
    document.removeEventListener("keydown", this.boundKeydown)
    document.removeEventListener("turbo:before-stream-render", this.boundBeforeStreamRender)
    document.removeEventListener("turbo:after-stream-render", this.boundAfterStreamRender)

    const publishedInput = this.publishedInput
    if (publishedInput) {
      publishedInput.removeEventListener("change", this.boundPublishedChange)
    }
  }

  // Auto-save management
  startAutoSave() {
    // Autosave disabled - do nothing
    return;
    // if (!this.autoSaveRunning) {
    //   this.autoSaveRunning = true;
    //   this.clearTimer('autoSaveTimer')
    //   this.autoSaveTimer = setInterval(() => this.performAutoSave(), this.intervalValue)
    // }
  }

  stopAutoSave() {
    this.autoSaveRunning = false;
    this.clearTimer('autoSaveTimer')
  }

  performAutoSave() {
    if (this.isSubmitting) return


    // Only auto-save if form has changes
    if (!this.formDirty) {
      return
    }

    if (this.isPublished) {
      this.setStatus("Auto-save disabled (published post)", "warning");
      this.stopAutoSave();
      return
    }

    // Save scroll position before autosave
    this.saveScrollPosition()

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

    // Don't restart auto-save since it's disabled
    // setTimeout(() => this.startAutoSave(), 1000)
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
      this.setStatus("Auto-save cancelled - Published state changed", "warning")
      return
    }

    if (event.detail.success) {
      // Reset form dirty state after successful save
      this.formDirty = false

      if (this.isPublished) {
        this.stopAutoSave()
        this.setStatus("Saved", "success")
      } else {
        this.setStatus("Saved", "success")
        this.setStatusWithDelay("Autosave temporarily disabled due to a bug", 3000, "warning")
      }
    } else {
      this.setStatus("Save failed", "error")
      this.setStatusWithDelay("Autosave temporarily disabled due to a bug", 5000, "warning")
    }
  }

  handlePublishedChange(event) {
    // Autosave is disabled, so this handler doesn't need to do anything
    return;
    // If auto-save is currently in progress, mark it for abortion
    if (this.isAutoSaving) {
      this.abortAutoSave = true
    }

    if (event.target.value === "true") {
      this.stopAutoSave()
      this.setStatus("Auto-save disabled (manual save only)", "warning")
    } else {
      this.startAutoSave()
      this.setStatus("Auto-save re-enabled", "info")
    }
  }

  handleFormInput() {
    this.formDirty = true
    // Autosave disabled - don't start autosave on input
    // this.startAutoSave()
  }

  // Helper methods
  get publishedInput() {
    return this.formTarget.querySelector('input[name*="[published]"]')
  }

  get isPublished() {
    return this.publishedInput?.value === "true"
  }

  setStatus(message, type = "default") {
    if (!this.hasStatusTarget) return

    this.statusTarget.textContent = message
    this.statusTarget.className = this.getBadgeClass(type)
  }

  setStatusWithDelay(message, delay, type = "default") {
    this.clearTimer('statusTimeout')
    this.statusTimeout = setTimeout(() => this.setStatus(message, type), delay)
  }

  getBadgeClass(type) {
    const baseClass = "badge badge-soft badge-sm"
    const typeClasses = {
      success: "badge-success",
      error: "badge-error",
      warning: "badge-warning",
      info: "badge-neutral",
      default: "badge-neutral"
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

  // Scroll position management
  saveScrollPosition() {
    // Save scroll position for all scrollable elements
    const scrollableElements = document.querySelectorAll('[data-marksmith-editor], .marksmith-editor, .textarea, textarea')
    scrollableElements.forEach(element => {
      if (element.scrollHeight > element.clientHeight) {
        this.scrollPositions.set(element, {
          scrollTop: element.scrollTop,
          scrollLeft: element.scrollLeft
        })
      }
    })

    // Also save window scroll position
    this.scrollPositions.set(window, {
      scrollTop: window.scrollY,
      scrollLeft: window.scrollX
    })
  }

  restoreScrollPosition() {
    // Restore scroll positions for all saved elements
    this.scrollPositions.forEach((position, element) => {
      if (element === window) {
        window.scrollTo(position.scrollLeft, position.scrollTop)
      } else if (document.contains(element)) {
        element.scrollTop = position.scrollTop
        element.scrollLeft = position.scrollLeft
      }
    })

    // Clear saved positions after restoration
    this.scrollPositions.clear()
  }

  handleBeforeStreamRender(event) {
    // Only save scroll position during autosave
    if (this.isAutoSaving) {
      this.saveScrollPosition()
    }
  }

  handleAfterStreamRender(event) {
    // Only restore scroll position during autosave
    if (this.isAutoSaving) {
      // Use requestAnimationFrame to ensure DOM has been updated
      requestAnimationFrame(() => {
        this.restoreScrollPosition()
      })
    }
  }
}
