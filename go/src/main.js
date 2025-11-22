// Import styles
import './main.css'

// Import and initialize Alpine.js
import Alpine from 'alpinejs'

// Make Alpine available globally
window.Alpine = Alpine

// Global toast store
Alpine.store('toasts', {
  items: [],
  nextId: 1,

  show(message, type = 'success') {
    const id = this.nextId++
    const toast = {
      id,
      message,
      type,
      visible: true
    }

    this.items.push(toast)

    setTimeout(() => {
      this.hide(id)
    }, 4000)
  },

  hide(id) {
    const toast = this.items.find(t => t.id === id)
    if (toast) {
      toast.visible = false
      setTimeout(() => {
        this.items = this.items.filter(t => t.id !== id)
      }, 300)
    }
  }
})

// Mermaid Alpine component
Alpine.data('mermaid', () => ({
  mermaidInitialized: false,

  async init() {
    await this.initializeMermaid()
  },

  async initializeMermaid() {
    // Goldmark renders as <pre><code class="language-mermaid">
    const codeElements = this.$el.querySelectorAll('code.language-mermaid')

    for (const codeElement of codeElements) {
      const preElement = codeElement.parentElement
      if (preElement && preElement.tagName === 'PRE') {
        await this.processMermaidElement(preElement, codeElement)
      }
    }
  },

  async processMermaidElement(preElement, codeElement) {
    try {
      // Dynamically import mermaid only when needed
      const mermaidModule = await import('mermaid')
      const mermaid = mermaidModule.default || mermaidModule

      // Initialize mermaid with configuration (only once globally)
      if (!window.mermaidInitialized) {
        // Detect current theme from DaisyUI
        const currentTheme = document.documentElement.getAttribute('data-theme')
        const darkThemes = ['dark', 'synthwave', 'halloween', 'forest', 'black', 'luxury', 'dracula', 'business', 'night', 'coffee', 'dim', 'sunset']
        const isDark = darkThemes.includes(currentTheme) || (!currentTheme && window.matchMedia('(prefers-color-scheme: dark)').matches)

        mermaid.initialize({
          startOnLoad: false,
          theme: isDark ? 'dark' : 'default'
        })
        window.mermaidInitialized = true
      }

      const diagramText = codeElement.textContent.trim()

      if (!diagramText) {
        return
      }

      // Generate a unique ID for the diagram
      const diagramId = `mermaid-${crypto.randomUUID()}`

      // Create a div to hold the rendered SVG
      const diagramDiv = document.createElement('div')
      diagramDiv.className = 'mermaid-diagram'
      diagramDiv.id = diagramId

      // Render the diagram
      const { svg } = await mermaid.render(`${diagramId}-svg`, diagramText)
      diagramDiv.innerHTML = svg

      // Replace the pre element with the rendered diagram
      preElement.parentNode.replaceChild(diagramDiv, preElement)

    } catch (error) {
      console.error('Error rendering mermaid diagram:', error)
      preElement.classList.add('mermaid-error')
    }
  }
}))

// Blog settings: Emoji picker with Choices.js
Alpine.data('emojiPicker', () => ({
  choices: null,
  emojiData: [],
  emojiLookup: new Map(),

  async init() {
    await this.loadEmojiData()
    await this.initializeChoices()
    this.setInitialValue()
  },

  async loadEmojiData() {
    try {
      const response = await fetch('/openmoji-map.json')
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      this.emojiData = await response.json()
      this.processEmojiData()
    } catch (error) {
      console.error('Failed to load emoji data:', error)
    }
  },

  processEmojiData() {
    this.emojiData.forEach(emoji => {
      this.emojiLookup.set(emoji.emoji, emoji)
    })
  },

  createGroupedChoices() {
    const groups = {}
    this.emojiData.forEach(emoji => {
      const group = emoji.group || 'other'
      if (!groups[group]) groups[group] = []
      groups[group].push({
        value: emoji.emoji,
        label: `<img src="/openmoji-svg-color/${emoji.hexcode}.svg" alt="${emoji.emoji}" class="w-6 h-6 inline-block mr-2" loading="lazy"> ${emoji.annotation}`,
        customProperties: {
          hexcode: emoji.hexcode,
          annotation: emoji.annotation,
          tags: emoji.tags || '',
          openmoji_tags: emoji.openmoji_tags || ''
        }
      })
    })

    return Object.entries(groups).map(([groupName, choices]) => ({
      label: this.formatGroupName(groupName),
      disabled: false,
      choices
    }))
  },

  formatGroupName(name) {
    return name.split('-').map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(' ')
  },

  async initializeChoices() {
    const Choices = (await import('choices.js')).default
    const selectElement = this.$refs.select

    this.choices = new Choices(selectElement, {
      removeItems: true,
      removeItemButton: true,
      duplicateItemsAllowed: false,
      addItems: false,
      placeholder: true,
      placeholderValue: 'Select an emoji...',
      searchEnabled: true,
      searchPlaceholderValue: 'Search emojis by name or tags...',
      noResultsText: 'No emojis found',
      shouldSort: false,
      position: 'bottom',
      allowHTML: true,
      searchResultLimit: 20,
      searchFields: ['label', 'customProperties.annotation', 'customProperties.tags', 'customProperties.openmoji_tags']
    })

    this.choices.setChoices(this.createGroupedChoices(), 'value', 'label', false)

    selectElement.addEventListener('change', () => {
      const selectedValue = this.choices.getValue(true)
      this.$refs.input.value = selectedValue || ''
      this.$refs.input.dispatchEvent(new Event('input', { bubbles: true }))
    })
  },

  setInitialValue() {
    const currentValue = this.$refs.input.value
    if (currentValue) {
      this.choices.setChoiceByValue(currentValue)
    }
  },

  destroy() {
    this.choices?.destroy()
    this.emojiLookup?.clear()
  }
}))

// Blog settings: Theme selector with preview
Alpine.data('themeSelector', (currentTheme) => ({
  selectedTheme: currentTheme || 'light',
  dropdownOpen: false,

  selectTheme(theme) {
    this.selectedTheme = theme
    this.dropdownOpen = false

    // Update hidden field
    this.$refs.hiddenField.value = theme

    // Update preview in button
    this.$refs.buttonText.textContent = theme
    this.$refs.buttonPreview.setAttribute('data-theme', theme)

    // Apply theme immediately
    document.documentElement.setAttribute('data-theme', theme)

    // Auto-submit form
    this.$el.closest('form').requestSubmit()
  }
}))

// Blog deletion confirmation
Alpine.data('blogDelete', (subdomain) => ({
  showModal: false,
  showFinalModal: false,
  confirmationInput: '',
  errorMessage: '',

  confirmDelete() {
    this.showModal = true
    this.confirmationInput = ''
    this.errorMessage = ''
    this.$nextTick(() => {
      this.$refs.confirmInput?.focus()
    })
  },

  checkMatch() {
    if (this.confirmationInput.length > 0 && this.confirmationInput !== subdomain) {
      this.errorMessage = 'Subdomain does not match. Please try again.'
    } else {
      this.errorMessage = ''
    }
  },

  get isValid() {
    return this.confirmationInput === subdomain
  },

  proceedToFinal() {
    if (this.isValid) {
      this.showModal = false
      this.showFinalModal = true
    }
  },

  cancelModal() {
    this.showModal = false
    this.showFinalModal = false
    this.confirmationInput = ''
    this.errorMessage = ''
  },

  deleteBlog() {
    this.$refs.deleteForm?.submit()
  }
}))

// Domain downcase helper
Alpine.data('domainDowncase', () => ({
  downcaseInput(event) {
    const input = event.target
    const start = input.selectionStart
    const end = input.selectionEnd
    input.value = input.value.toLowerCase()
    input.setSelectionRange(start, end)
  }
}))

// Security page notifications
Alpine.data('securityPage', (successMessage, errorMessage) => ({
  submitting: false,
  savingProfile: false,
  savingPassword: false,
  showCurrentPassword: false,
  showNewPassword: false,
  showConfirmPassword: false,
  profileError: '',
  passwordError: '',

  init() {
    const successMessages = {
      'password_updated': 'Password updated successfully',
      'token_created': 'Token created successfully',
      'token_deleted': 'Token deleted successfully',
      'profile_updated': 'Profile updated successfully'
    }

    const errorMessages = {
      'password_required': 'Password is required',
      'password_mismatch': 'Passwords do not match',
      'name_required': 'Token name is required',
      'invalid_date': 'Invalid expiration date',
      'expiration_must_be_future': 'Expiration date must be in the future',
      'email_required': 'Email is required',
      'invalid_password': 'Current password is incorrect'
    }

    if (successMessage && successMessages[successMessage]) {
      this.$store.toasts.show(successMessages[successMessage], 'success')
    }

    if (errorMessage && errorMessages[errorMessage]) {
      this.$store.toasts.show(errorMessages[errorMessage], 'error')
    }
  },

  async submitProfile(event) {
    event.preventDefault()
    this.savingProfile = true
    this.profileError = ''

    const formData = new FormData(event.target)

    try {
      const response = await fetch('/dashboard/security/profile', {
        method: 'POST',
        headers: {
          'Accept': 'application/json'
        },
        body: formData
      })

      const data = await response.json()

      if (data.success) {
        this.$store.toasts.show(data.message, 'success')
        // Clear password fields after successful update
        const newPasswordField = event.target.querySelector('input[name="new_password"]')
        const confirmPasswordField = event.target.querySelector('input[name="confirm_password"]')
        if (newPasswordField) newPasswordField.value = ''
        if (confirmPasswordField) confirmPasswordField.value = ''
      } else {
        this.profileError = data.message
      }
    } catch (error) {
      this.profileError = 'Failed to update profile'
      this.$store.toasts.show('Network error. Please try again.', 'error')
    } finally {
      this.savingProfile = false
    }
  },

  async submitPassword(event) {
    event.preventDefault()
    this.savingPassword = true
    this.passwordError = ''

    const formData = new FormData(event.target)

    try {
      const response = await fetch('/dashboard/security/password', {
        method: 'POST',
        headers: {
          'Accept': 'application/json'
        },
        body: formData
      })

      const data = await response.json()

      if (data.success) {
        this.$store.toasts.show(data.message, 'success')
        event.target.reset()
      } else {
        this.passwordError = data.message
      }
    } catch (error) {
      this.passwordError = 'Failed to update password'
      this.$store.toasts.show('Network error. Please try again.', 'error')
    } finally {
      this.savingPassword = false
    }
  },

  hasProfileError() {
    return this.profileError !== ''
  },

  hasPasswordError() {
    return this.passwordError !== ''
  },

  getCurrentPasswordError() {
    return this.passwordError.includes('incorrect') || this.passwordError.includes('Current password')
  },

  getNewPasswordError() {
    return this.passwordError.includes('match') || this.passwordError.includes('do not match')
  }
}))

// Token list management
Alpine.data('tokenList', () => ({
  tokens: [],
  loading: false,
  submitting: false,

  async init() {
    await this.fetchTokens()
  },

  async fetchTokens() {
    this.loading = true
    try {
      const response = await fetch('/dashboard/tokens', {
        headers: {
          'Accept': 'application/json'
        }
      })

      if (response.ok) {
        const data = await response.json()
        // Ensure tokens is always an array, even if server returns null
        this.tokens = data || []
      } else {
        console.error('Failed to fetch tokens:', response.status)
        this.$store.toasts.show('Failed to load tokens', 'error')
        this.tokens = []
      }
    } catch (error) {
      console.error('Error fetching tokens:', error)
      this.$store.toasts.show('Network error loading tokens', 'error')
      this.tokens = []
    } finally {
      this.loading = false
    }
  },

  async createToken(event) {
    event.preventDefault()

    if (this.submitting) return

    this.submitting = true

    const form = event.target
    const formData = new FormData(form)

    try {
      const response = await fetch(form.action, {
        method: 'POST',
        headers: {
          'Accept': 'application/json'
        },
        body: formData
      })

      const data = await response.json()

      if (response.ok && data.success) {
        this.$store.toasts.show(data.message || 'Token created successfully', 'success')
        form.reset()

        // Add the new token to the list
        if (data.token) {
          this.tokens.unshift(data.token)
        }
      } else {
        this.$store.toasts.show(data.message || 'Failed to create token', 'error')
      }
    } catch (error) {
      console.error('Token creation error:', error)
      this.$store.toasts.show('Network error. Please try again.', 'error')
    } finally {
      this.submitting = false
    }
  },

  async deleteToken(tokenId) {
    if (!confirm('Are you sure you want to revoke this token?')) {
      return
    }

    try {
      const response = await fetch(`/dashboard/tokens/${tokenId}/delete`, {
        method: 'POST',
        headers: {
          'Accept': 'application/json'
        }
      })

      const data = await response.json()

      if (response.ok && data.success) {
        this.$store.toasts.show(data.message || 'Token deleted successfully', 'success')

        // Remove token from the list
        this.tokens = this.tokens.filter(t => t.id !== tokenId)
      } else {
        this.$store.toasts.show(data.message || 'Failed to delete token', 'error')
      }
    } catch (error) {
      console.error('Token deletion error:', error)
      this.$store.toasts.show('Network error. Please try again.', 'error')
    }
  },

  formatDate(dateString) {
    if (!dateString) return ''

    const date = new Date(dateString)
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: '2-digit',
      year: 'numeric'
    })
  }
}))

// Post form autosave
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

// Tag choices with Choices.js
Alpine.data('tagChoices', (existingTags, currentTags) => ({
  choices: null,
  existingTags: existingTags || [],
  currentTags: currentTags || '',

  async init() {
    await this.initializeChoices()
  },

  async initializeChoices() {
    const Choices = (await import('choices.js')).default
    const selectElement = this.$refs.select
    const hiddenInput = this.$refs.input

    // Clear any existing options
    selectElement.innerHTML = ''

    // Initialize Choices.js
    this.choices = new Choices(selectElement, {
      removeItems: true,
      removeItemButton: true,
      duplicateItemsAllowed: false,
      addItems: true,
      addChoices: true,
      addItemFilter: (value) => {
        return value.trim() !== ''
      },
      placeholder: true,
      placeholderValue: 'Add tags...',
      searchEnabled: true,
      searchPlaceholderValue: 'Type to search or add new tags',
      noResultsText: 'Press Enter to add "<b>{{value}}</b>"',
      addItemText: (value) => {
        return `Press Enter to add <b>"${value}"</b>`
      },
      maxItemCount: -1,
      shouldSort: false,
      position: 'bottom'
    })

    // Parse current tags
    let currentTagsList = []
    if (this.currentTags) {
      currentTagsList = this.currentTags.split(',')
        .map(tag => tag.trim())
        .filter(tag => tag)
    }

    // Build all choices
    const allChoices = []

    // Add existing tags from the database
    this.existingTags.forEach(tag => {
      allChoices.push({
        value: tag,
        label: tag,
        selected: currentTagsList.includes(tag)
      })
    })

    // Add any current tags that aren't in the existing tags list
    const customTags = currentTagsList.filter(tag => !this.existingTags.includes(tag))
    customTags.forEach(tag => {
      allChoices.push({
        value: tag,
        label: tag,
        selected: true
      })
    })

    // Remove duplicate choices
    const uniqueChoices = allChoices.reduce((acc, current) => {
      const exists = acc.find(item => item.value === current.value)
      if (!exists) {
        acc.push(current)
      } else if (current.selected && !exists.selected) {
        exists.selected = true
      }
      return acc
    }, [])

    // Set all choices
    if (uniqueChoices.length > 0) {
      this.choices.setChoices(uniqueChoices, 'value', 'label', true)
    }

    // Update hidden input when selection changes
    selectElement.addEventListener('change', () => {
      this.updateHiddenInput()
    })

    // Apply focus/blur styling
    const containerOuter = this.$el.querySelector('.choices')
    if (containerOuter) {
      this.$el.addEventListener('focusin', (e) => {
        if (e.target.closest('.choices')) {
          containerOuter.classList.add('is-focused')
        }
      })

      this.$el.addEventListener('focusout', (e) => {
        if (!e.relatedTarget || !e.relatedTarget.closest('.choices')) {
          containerOuter.classList.remove('is-focused')
        }
      })
    }
  },

  updateHiddenInput() {
    const values = this.choices.getValue(true)
    this.$refs.input.value = values.join(', ')

    // Trigger input event for autosave
    this.$refs.input.dispatchEvent(new Event('input', { bubbles: true }))

    // Trigger change event on the form to mark it dirty and trigger autosave
    const form = this.$el.closest('form')
    if (form) {
      form.dispatchEvent(new Event('change', { bubbles: true }))
    }
  },

  destroy() {
    this.choices?.destroy()
  }
}))

// Start Alpine
Alpine.start()
