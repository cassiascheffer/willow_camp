// Tag multi-select component with Choices.js
export function registerTagChoicesComponent(Alpine) {
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
}
