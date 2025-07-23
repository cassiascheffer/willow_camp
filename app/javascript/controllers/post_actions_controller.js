import { Controller } from "@hotwired/stimulus"

// Manages the post actions dropdown menu
export default class extends Controller {
  static targets = ["dropdown"]

  closeDropdown() {
    // Close the DaisyUI dropdown by removing focus
    if (this.hasDropdownTarget) {
      const dropdownTrigger = this.dropdownTarget.querySelector('[role="button"]')
      if (dropdownTrigger) {
        dropdownTrigger.blur()
      }
    }
  }
}