import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const form = this.element
    const checkbox = event.target
    const originalState = !checkbox.checked
    
    // Update the checkbox value based on its checked state
    checkbox.value = checkbox.checked ? "true" : "false"
    
    // Submit the form
    form.requestSubmit()
    
    // Handle potential errors by reverting checkbox state if request fails
    form.addEventListener('turbo:submit-end', (e) => {
      if (!e.detail.success) {
        checkbox.checked = originalState
        checkbox.value = originalState ? "true" : "false"
      }
    }, { once: true })
  }
}