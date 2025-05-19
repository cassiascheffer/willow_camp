import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["form"]

    connect() {
        // Nothing specific needed on connect
    }

    // This method is triggered by our custom Turbo Stream response
    reset() {
        if (this.hasFormTarget) {
            // Clear all form fields
            this.formTarget.reset()

            // Additionally, clear any hidden inputs that might not get reset by default
            this.formTarget.querySelectorAll('input').forEach(input => {
                if (input.type !== 'submit' && input.type !== 'button') {
                    input.value = ''
                }
            })

            // Clear any select elements
            this.formTarget.querySelectorAll('select').forEach(select => {
                select.selectedIndex = 0
            })

            // Clear any textareas
            this.formTarget.querySelectorAll('textarea').forEach(textarea => {
                textarea.value = ''
            })

            // Remove any error messages that might still be showing
            const errorExplanation = this.formTarget.querySelector('#error_explanation')
            if (errorExplanation) {
                errorExplanation.remove()
            }
        }
    }
}
