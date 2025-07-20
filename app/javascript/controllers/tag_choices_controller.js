import { Controller } from "@hotwired/stimulus"
import Choices from "choices.js"

export default class extends Controller {
  static targets = ["input", "select"]
  static values = {
    existingTags: String,
    placeholder: { type: String, default: "Add tags..." }
  }

  connect() {
    // Ensure the select element exists before initializing
    if (this.hasSelectTarget) {
      this.initializeChoices()
    }
  }

  disconnect() {
    if (this.choices) {
      this.choices.destroy()
    }
  }

  initializeChoices() {
    const selectElement = this.selectTarget

    // Clear any existing options in the select element
    selectElement.innerHTML = ''

    // Initialize Choices.js with configuration
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
      placeholderValue: this.placeholderValue,
      searchEnabled: true,
      searchPlaceholderValue: 'Type to search or add new tags',
      noResultsText: 'Press Enter to add "<b>{{value}}</b>"',
      addItemText: (value) => {
        return `Press Enter to add <b>"${value}"</b>`
      },
      maxItemCount: -1,
      shouldSort: false,
      position: 'bottom',
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

    // Get current tags from hidden input
    let currentTags = []
    if (this.inputTarget.value) {
      currentTags = this.inputTarget.value.split(',')
        .map(tag => tag.trim())
        .filter(tag => tag)
    }

    // Build all choices at once
    const allChoices = []

    // Parse existing tags from JSON string
    let existingTags = []
    if (this.existingTagsValue) {
      try {
        existingTags = JSON.parse(this.existingTagsValue)
      } catch (e) {
        existingTags = []
      }
    }

    // Add existing tags from the database
    if (existingTags && existingTags.length > 0) {
      existingTags.forEach(tag => {
        allChoices.push({
          value: tag,
          label: tag,
          selected: currentTags.includes(tag)
        })
      })
    }

    // Add any current tags that aren't in the existing tags list (custom tags)
    const customTags = currentTags.filter(tag => !existingTags.includes(tag))
    customTags.forEach(tag => {
      allChoices.push({
        value: tag,
        label: tag,
        selected: true
      })
    })

    // Remove duplicate choices based on value
    const uniqueChoices = allChoices.reduce((acc, current) => {
      const exists = acc.find(item => item.value === current.value)
      if (!exists) {
        acc.push(current)
      } else if (current.selected && !exists.selected) {
        // If the current one is selected but the existing one isn't, update it
        exists.selected = true
      }
      return acc
    }, [])

    // Set all choices at once if we have any
    if (uniqueChoices.length > 0) {
      this.choices.setChoices(uniqueChoices, 'value', 'label', true)
    }

    // Update hidden input when selection changes
    selectElement.addEventListener('change', this.updateHiddenInput.bind(this))

    // Add focus/blur event handlers to apply appropriate styling
    const containerOuter = this.element.querySelector('.choices')
    if (containerOuter) {
      // Apply focused class when input is focused
      this.element.addEventListener('focusin', (e) => {
        if (e.target.closest('.choices')) {
          containerOuter.classList.add('is-focused')
        }
      })

      // Remove focused class when input loses focus
      this.element.addEventListener('focusout', (e) => {
        if (!e.relatedTarget || !e.relatedTarget.closest('.choices')) {
          containerOuter.classList.remove('is-focused')
        }
      })
    }
  }

  updateHiddenInput(event) {
    // Get raw values from the Choices.js component
    const values = this.choices.getValue(true)

    // Update hidden input with comma-separated tag string
    this.inputTarget.value = values.join(', ')

    // Trigger input event for autosave
    this.inputTarget.dispatchEvent(new Event('input', { bubbles: true }))

    // Ensure proper height is maintained after content changes
    this.adjustChoicesHeight()
  }

  adjustChoicesHeight() {
    // Get the choices container and ensure it has appropriate height
    const choicesInner = this.element.querySelector('.choices__inner')
    if (choicesInner) {
      // Make sure we have minimum height when no items or just a few items
      const itemCount = this.choices.getValue(true).length
      if (itemCount === 0) {
        choicesInner.style.minHeight = '3rem'
      } else {
        choicesInner.style.minHeight = null
      }
    }
  }
}
