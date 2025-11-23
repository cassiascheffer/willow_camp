// Blog favicon emoji picker component with Choices.js
import Choices from 'choices.js'

export function registerEmojiPickerComponent(Alpine) {
  Alpine.data('emojiPicker', (blogSubdomain = null) => ({
    choices: null,
    emojiData: [],
    emojiLookup: new Map(),
    blogSubdomain: blogSubdomain,

    init() {
      // Load data and initialize asynchronously without blocking
      this.loadAndInitialize()
    },

    async loadAndInitialize() {
      await this.loadEmojiData()
      this.initializeChoices()
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

    initializeChoices() {
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

        // Update favicon immediately and save in background
        if (selectedValue) {
          this.updateFavicon(selectedValue)
          this.saveFavicon(selectedValue)
        }
      })
    },

    setInitialValue() {
      const currentValue = this.$refs.input.value
      if (currentValue) {
        this.choices.setChoiceByValue(currentValue)
      }
    },

    updateFavicon(emoji) {
      // Get hexcode for the emoji from our lookup
      const emojiData = this.emojiLookup.get(emoji)
      if (!emojiData) {
        console.warn('Could not find emoji data for:', emoji)
        return
      }

      // Update all favicon links to use the new emoji's hexcode
      const hexcode = emojiData.hexcode

      // Update ICO favicon
      const icoLink = document.querySelector('link[rel="icon"][sizes="32x32"]')
      if (icoLink) {
        icoLink.href = `/openmoji-32x32-ico/${hexcode}.ico`
      }

      // Update SVG favicon
      const svgLink = document.querySelector('link[rel="icon"][type="image/svg+xml"]')
      if (svgLink) {
        svgLink.href = `/openmoji-svg-color/${hexcode}.svg`
      }

      // Update Apple touch icon
      const appleLink = document.querySelector('link[rel="apple-touch-icon"]')
      if (appleLink) {
        appleLink.href = `/openmoji-apple-touch-icon-180x180/${hexcode}.png`
      }
    },

    async saveFavicon(emoji) {
      // Only save if we have a blog subdomain
      if (!this.blogSubdomain) {
        console.warn('No blog subdomain provided, skipping save')
        return
      }

      try {
        const response = await fetch(`/dashboard/blogs/${this.blogSubdomain}/settings/favicon`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({ favicon_emoji: emoji })
        })

        if (!response.ok) {
          console.error('Failed to save favicon:', response.statusText)
        }
      } catch (error) {
        console.error('Error saving favicon:', error)
      }
    },

    destroy() {
      this.choices?.destroy()
      this.emojiLookup?.clear()
    }
  }))
}
