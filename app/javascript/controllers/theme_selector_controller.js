import { Controller } from "@hotwired/stimulus"

// Theme selection UI controller for dropdown theme selectors
// Manages dropdown interactions, form updates, and communicates with theme controller
export default class extends Controller {
  static outlets = ["theme"]

  connect() {
    // No special initialization needed for dropdowns
  }

  // Preview theme on hover
  previewTheme(event) {
    const theme = this.extractThemeFromEvent(event)
    if (theme && this.hasThemeOutlet) {
      this.themeOutlet.applyTheme(theme, 'fast')
    }
  }

  // Restore current theme when hover ends
  restoreTheme(event) {
    if (this.hasThemeOutlet) {
      this.themeOutlet.applyCurrentTheme('fast')
    }
  }



  // Handle theme selection from dropdown
  selectTheme(event) {
    const button = event.currentTarget
    const themeValue = button.dataset.themeValue
    const themeType = button.dataset.themeType

    if (!themeValue || !themeType) return

    this.updateFormField(themeType, themeValue)
    this.updateDropdownDisplay(button, themeValue, themeType)
    this.updateDropdownSelection(button)
    this.updateThemeControllerValues(themeType, themeValue)

    if (this.hasThemeOutlet) {
      this.themeOutlet.applyTheme(themeValue, 'normal')
    }

    // Close the dropdown
    this.closeDropdown(button)
  }

  // Extract theme value from event target
  extractThemeFromEvent(event) {
    return event.target.dataset.themeValue || event.target.value
  }

  // Form and UI updates
  updateFormField(themeType, themeValue) {
    const hiddenInput = this.element.querySelector(`input[name="user[${themeType}_theme]"]`)
    if (hiddenInput) {
      hiddenInput.value = themeValue
    }
  }

  updateDropdownDisplay(button, themeValue, themeType) {
    const dropdown = button.closest('.dropdown')
    if (!dropdown) return

    const trigger = dropdown.querySelector('[role="button"]')
    if (!trigger) return

    // Update the theme preview in the trigger button
    const themePreview = trigger.querySelector('[data-theme]')
    if (themePreview) {
      themePreview.setAttribute('data-theme', themeValue)
    }

    // Update the theme name text in the trigger button
    const themeNameSpan = trigger.querySelector('span.capitalize')
    if (themeNameSpan) {
      themeNameSpan.textContent = themeValue
    }
  }

  updateThemeControllerValues(themeType, themeValue) {
    if (!this.hasThemeOutlet) return

    const currentLight = themeType === 'light' ? themeValue : this.themeOutlet.lightThemeValue
    const currentDark = themeType === 'dark' ? themeValue : this.themeOutlet.darkThemeValue

    this.themeOutlet.updateThemeValues(currentLight, currentDark)
  }

  // Dropdown selection management
  updateDropdownSelection(selectedButton) {
    const dropdown = selectedButton.closest('.dropdown')
    if (!dropdown) return

    const menu = dropdown.querySelector('.menu')
    if (!menu) return

    this.resetDropdownSelection(menu)
    this.setSelectedState(selectedButton)
  }

  resetDropdownSelection(menu) {
    menu.querySelectorAll('button').forEach(button => {
      const checkmark = button.querySelector('svg')
      if (checkmark) {
        checkmark.style.display = 'none'
      }
    })
  }

  setSelectedState(button) {
    // Show checkmark for selected button, or create one if it doesn't exist
    let checkmark = button.querySelector('svg')
    if (!checkmark) {
      checkmark = document.createElement('svg')
      checkmark.className = 'w-4 h-4 text-primary'
      checkmark.setAttribute('fill', 'currentColor')
      checkmark.setAttribute('viewBox', '0 0 20 20')
      checkmark.innerHTML = '<path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>'
      button.appendChild(checkmark)
    }
    checkmark.style.display = 'block'
  }

  closeDropdown(button) {
    const dropdown = button.closest('.dropdown')
    if (dropdown) {
      const trigger = dropdown.querySelector('[role="button"]')
      if (trigger) {
        trigger.blur()
        // Force close by removing focus from any active element
        if (document.activeElement) {
          document.activeElement.blur()
        }
      }
    }
  }
}
