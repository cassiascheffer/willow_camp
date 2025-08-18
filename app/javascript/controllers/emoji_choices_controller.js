import { Controller } from "@hotwired/stimulus"
import Choices from "choices.js"

export default class extends Controller {
  static targets = ["input", "select"]
  static values = {
    placeholder: { type: String, default: "Select an emoji..." },
    defaultHexcode: { type: String, default: "1F3D5" },
    emojiBasePath: { type: String, default: "/openmoji-svg-color" }
  }

  async connect() {
    if (!this.hasSelectTarget) return

    await this.loadEmojiData()
    this.processEmojiData()
    this.initializeChoices()
    this.setInitialValue()
  }

  async loadEmojiData() {
    try {
      const response = await fetch('/openmoji-map.json')
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      this.rawEmojiData = await response.json()
    } catch (error) {
      console.error('Failed to load emoji data:', error)
      this.rawEmojiData = []
    }
  }

  processEmojiData() {
    this.emojiLookup = new Map()
    this.groupedChoices = this.createGroupedChoices()
  }

  createGroupedChoices() {
    const groups = {}

    this.rawEmojiData.forEach(emoji => {
      // Store in lookup map
      this.emojiLookup.set(emoji.emoji, emoji)

      // Group emojis
      const group = emoji.group || 'other'
      if (!groups[group]) {
        groups[group] = []
      }

      groups[group].push(this.createChoiceItem(emoji))
    })

    return Object.entries(groups).map(([groupName, choices]) => ({
      label: this.formatGroupName(groupName),
      disabled: false,
      choices
    }))
  }

  createChoiceItem(emoji) {
    return {
      value: emoji.emoji,
      label: this.createEmojiLabel(emoji),
      customProperties: {
        hexcode: emoji.hexcode,
        annotation: emoji.annotation,
        tags: emoji.tags || '',
        openmoji_tags: emoji.openmoji_tags || ''
      }
    }
  }

  createEmojiLabel(emoji) {
    const imgPath = `${this.emojiBasePathValue}/${emoji.hexcode}.svg`
    return `<img src="${imgPath}" alt="${emoji.emoji}" class="w-6 h-6 inline-block mr-2" loading="lazy"> ${emoji.annotation}`
  }

  formatGroupName(name) {
    return name
      .split('-')
      .map(word => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ')
  }

  initializeChoices() {
    this.clearSelect()

    this.choices = new Choices(this.selectTarget, {
      ...this.getChoicesConfig(),
      searchFields: ['label', 'customProperties.annotation', 'customProperties.tags', 'customProperties.openmoji_tags']
    })

    this.choices.setChoices(this.groupedChoices, 'value', 'label', false)
    this.selectTarget.addEventListener('change', this.handleSelectionChange.bind(this))
  }

  getChoicesConfig() {
    return {
      removeItems: true,
      removeItemButton: true,
      duplicateItemsAllowed: false,
      addItems: false,
      placeholder: true,
      placeholderValue: this.placeholderValue,
      searchEnabled: true,
      searchPlaceholderValue: 'Search emojis by name or tags...',
      noResultsText: 'No emojis found',
      shouldSort: false,
      position: 'bottom',
      allowHTML: true,
      searchResultLimit: 20
    }
  }

  setInitialValue() {
    const currentValue = this.inputTarget.value
    if (!currentValue) return

    this.choices.setChoiceByValue(currentValue)
    this.updateHexcode(currentValue)
  }

  handleSelectionChange() {
    const selectedValue = this.choices.getValue(true)
    this.inputTarget.value = selectedValue || ''
    this.updateHexcode(selectedValue)
    this.inputTarget.dispatchEvent(new Event('input', { bubbles: true }))
  }

  updateHexcode(emojiValue) {
    let hexcode = this.defaultHexcodeValue

    if (emojiValue && this.emojiLookup.has(emojiValue)) {
      hexcode = this.emojiLookup.get(emojiValue).hexcode
    }

    this.inputTarget.dataset.hexcode = hexcode
  }

  clearSelect() {
    this.selectTarget.innerHTML = ''
  }

  disconnect() {
    this.choices?.destroy()
    this.emojiLookup?.clear()
  }
}
