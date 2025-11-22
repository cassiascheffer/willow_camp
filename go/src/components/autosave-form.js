// Post form autosave component (30s + Cmd+S/Ctrl+S)
export function registerAutosaveFormComponent(Alpine) {
  Alpine.data('autosaveForm', (isEdit, blogId, postId, publishedValue) => ({
    // State
    saving: false,
    publishedValue: publishedValue || 'false',
    isDirty: false,
    saveStatus: null, // 'saving', 'saved', 'error'
    saveStatusText: '',
    autosaveTimer: null,
    scrollPosition: 0,
    originalValues: {},
    isEdit: isEdit || false,
    blogId: blogId || '',
    postId: postId || '',

    // Initialize
    init() {
      // Only enable autosave for edit mode
      if (!this.isEdit) return

      // Store original form values
      this.captureOriginalValues()

      // Start autosave timer (every 30 seconds)
      this.startAutosaveTimer()
    },

    // Capture original form values for dirty checking
    captureOriginalValues() {
      const form = this.$el.querySelector('form')
      const formData = new FormData(form)
      this.originalValues = {}
      for (let [key, value] of formData.entries()) {
        this.originalValues[key] = value
      }
    },

    // Mark form as dirty when changed
    markDirty() {
      this.isDirty = true
    },

    // Start periodic autosave timer
    startAutosaveTimer() {
      this.autosaveTimer = setInterval(() => {
        if (this.isDirty && !this.saving) {
          this.performAutosave()
        }
      }, 30000) // 30 seconds
    },

    // Trigger autosave manually (Cmd+S / Ctrl+S)
    triggerAutosave(event) {
      if (this.isEdit && !this.saving) {
        this.performAutosave()
      }
    },

    // Perform autosave
    async performAutosave() {
      if (!this.isEdit) return
      if (!this.postId) {
        console.error('Cannot autosave: no post ID')
        return
      }

      // Save current scroll position
      this.scrollPosition = window.scrollY

      // Set saving status
      this.saving = true
      this.saveStatus = 'saving'
      this.saveStatusText = 'Auto-save loading...'

      try {
        // Get form data using Alpine.js ref
        const form = this.$refs.form
        if (!form) {
          throw new Error('Form not found')
        }

        const formData = new FormData(form)

        // Convert to JSON
        const data = {}
        for (let [key, value] of formData.entries()) {
          data[key] = value
        }

        // Build URL
        const url = `/dashboard/blogs/${this.blogId}/posts/${this.postId}/autosave`
        console.log('Autosaving to:', url, data)

        // Send autosave request
        const response = await fetch(url, {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(data)
        })

        console.log('Autosave response:', response.status, response.statusText)

        if (response.ok) {
          // Parse response to get the generated slug
          const responseData = await response.json()

          // Update slug field with the backend-generated slug
          const slugInput = this.$el.querySelector('input[name="slug"]')
          if (slugInput && responseData.slug) {
            slugInput.value = responseData.slug
          }

          // Success
          this.saveStatus = 'saved'
          this.saveStatusText = 'Saved'
          this.isDirty = false

          // Hide success message after 2 seconds
          setTimeout(() => {
            this.saveStatus = null
          }, 2000)
        } else {
          // Error
          const errorData = await response.json().catch(() => ({}))
          console.error('Autosave failed:', response.status, errorData)
          this.saveStatus = 'error'
          this.saveStatusText = 'Error saving'
        }
      } catch (error) {
        // Network or other error
        console.error('Autosave error:', error)
        this.saveStatus = 'error'
        this.saveStatusText = 'Connection error'
      } finally {
        this.saving = false

        // Restore scroll position
        window.scrollTo(0, this.scrollPosition)
      }
    },

    // Handle form submission
    onSubmit(event) {
      this.saving = true
      // Clear autosave timer on submit
      if (this.autosaveTimer) {
        clearInterval(this.autosaveTimer)
      }
    }
  }))
}
