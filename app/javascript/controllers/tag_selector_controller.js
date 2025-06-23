import { Controller } from "@hotwired/stimulus"
import Choices from "choices.js"

// Connects to data-controller="tag-selector"
export default class extends Controller {
  static targets = ["select", "hiddenInput"]
  static values = {
    existingTags: Array,
    currentTags: String
  }

  connect() {
    // Small delay to ensure DOM is ready
    setTimeout(() => {
      this.initializeChoices()
    }, 10)
  }

  disconnect() {
    if (this.choices) {
      try {
        this.choices.destroy()
      } catch (error) {
        console.warn('Error destroying Choices instance:', error)
      }
      this.choices = null
    }
  }

  initializeChoices() {
    if (this.choices) {
      return // Already initialized
    }

    try {
      // Prepare choices from existing tags
      const choices = this.existingTagsValue.map(tag => ({
        value: tag,
        label: tag,
        selected: false
      }))

      // Initialize Choices.js
      this.choices = new Choices(this.selectTarget, {
      removeItemButton: true,
      duplicateItemsAllowed: false,
      editItems: true,
      addItems: true,
      searchEnabled: true,
      searchChoices: true,
      searchFloor: 1,
      searchResultLimit: 10,
      placeholder: true,
      placeholderValue: "Start typing to search or add tags...",
      noResultsText: "Press Enter to add this as a new tag",
      noChoicesText: "No tags to choose from",
      itemSelectText: "Press to select",
      addItemText: (value) => `Press Enter to add <b>"${value}"</b>`,
      maxItemText: (maxItemCount) => `Only ${maxItemCount} tags allowed`,
      classNames: {
        containerOuter: 'choices',
        containerInner: 'choices__inner',
        input: 'choices__input',
        inputCloned: 'choices__input--cloned',
        list: 'choices__list',
        listItems: 'choices__list--multiple',
        listSingle: 'choices__list--single',
        listDropdown: 'choices__list--dropdown',
        item: 'choices__item',
        itemSelectable: 'choices__item--selectable',
        itemDisabled: 'choices__item--disabled',
        itemChoice: 'choices__item--choice',
        placeholder: 'choices__placeholder',
        group: 'choices__group',
        groupHeading: 'choices__heading',
        button: 'choices__button',
        activeState: 'is-active',
        focusState: 'is-focused',
        openState: 'is-open',
        disabledState: 'is-disabled',
        highlightedState: 'is-highlighted',
        selectedState: 'is-selected',
        flippedState: 'is-flipped',
        loadingState: 'is-loading',
        noResults: 'has-no-results',
        noChoices: 'has-no-choices'
      }
    })

      // Set choices
      this.choices.setChoices(choices, 'value', 'label', false)

      // Set current values if any
      if (this.currentTagsValue) {
        const currentTags = this.currentTagsValue.split(',').map(tag => tag.trim()).filter(tag => tag)
        this.choices.setChoiceByValue(currentTags)
      }

      // Listen for changes and update hidden input
      this.selectTarget.addEventListener('change', () => {
        this.updateHiddenInput()
      })

      // Handle adding new items
      this.selectTarget.addEventListener('addItem', (event) => {
        this.updateHiddenInput()
      })

      // Handle removing items
      this.selectTarget.addEventListener('removeItem', (event) => {
        this.updateHiddenInput()
      })

    } catch (error) {
      console.error('Error initializing tag selector:', error)
      // Fallback: show the select element as a regular select
      this.selectTarget.style.display = 'block'
    }
  }

  updateHiddenInput() {
    if (!this.choices) return

    try {
      const selectedValues = this.choices.getValue(true)
      this.hiddenInputTarget.value = Array.isArray(selectedValues) ? selectedValues.join(', ') : ''
    } catch (error) {
      console.warn('Error updating hidden input:', error)
    }
  }
}
