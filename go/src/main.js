// Import styles
import './main.css'

// Import and initialize Alpine.js
import Alpine from 'alpinejs'

// Make Alpine available globally
window.Alpine = Alpine

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

// Start Alpine
Alpine.start()
