// Blog favicon emoji picker component with Choices.js
export function registerEmojiPickerComponent(Alpine) {
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
}
