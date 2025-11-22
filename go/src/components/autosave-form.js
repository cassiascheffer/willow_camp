// Post form autosave component (30s + Cmd+S/Ctrl+S)
export function registerAutosaveFormComponent(Alpine) {
  Alpine.data('autosaveForm', (blogId, postId, publishedValue) => ({
    // State
    saving: false,
    publishedValue: publishedValue || 'false',
    isDirty: false,
    saveStatus: null, // 'saving', 'saved', 'error'
    saveStatusText: '',
    autosaveTimer: null,
    scrollPosition: 0,
    originalValues: {},
    blogId: blogId || '',
    postId: postId || '',

    // Initialize
    init() {
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
      if (!this.saving) {
        this.performAutosave()
      }
    },

    // Perform autosave
    async performAutosave() {
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

        // Build URL (same as manual submit - both use UpdatePost handler)
        const url = `/dashboard/blogs/${this.blogId}/posts/${this.postId}`
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
    async onSubmit(event) {
      event.preventDefault()

      // Get which button was clicked to determine the intended published state
      const submitter = event.submitter
      const intendedPublished = submitter?.dataset?.published || this.publishedValue

      this.saving = true
      this.saveStatus = 'saving'
      this.saveStatusText = 'Saving...'

      try {
        const form = this.$refs.form
        if (!form) {
          throw new Error('Form not found')
        }

        const formData = new FormData(form)

        // Override the published value with the intended value from the button
        formData.set('published', intendedPublished)

        // Convert to JSON
        const data = {}
        for (let [key, value] of formData.entries()) {
          data[key] = value
        }

        // Always PUT (we're always editing an existing post)
        const url = `/dashboard/blogs/${this.blogId}/posts/${this.postId}`

        // Send request
        const response = await fetch(url, {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(data)
        })

        if (response.ok) {
          const responseData = await response.json()

          // Update slug field if returned
          if (responseData.slug) {
            const slugInput = this.$el.querySelector('input[name="slug"]')
            if (slugInput) {
              slugInput.value = responseData.slug
            }
          }

          // Update published_at field if returned
          if (responseData.published_at) {
            const publishedAtInput = this.$el.querySelector('input[name="published_at"]')
            if (publishedAtInput) {
              publishedAtInput.value = responseData.published_at
            }
          }

          // Update published state
          if (responseData.published !== undefined) {
            this.publishedValue = responseData.published ? 'true' : 'false'
          }

          // Show success message
          this.saveStatus = 'saved'
          this.saveStatusText = 'Saved'
          this.isDirty = false

          // Hide success message after 2 seconds
          setTimeout(() => {
            this.saveStatus = null
          }, 2000)
        } else {
          const errorData = await response.json().catch(() => ({}))
          console.error('Save failed:', response.status, errorData)
          this.saveStatus = 'error'
          this.saveStatusText = errorData.error || 'Error saving'
        }
      } catch (error) {
        console.error('Save error:', error)
        this.saveStatus = 'error'
        this.saveStatusText = 'Error saving'
      } finally {
        this.saving = false
      }
    }
  }))
}
