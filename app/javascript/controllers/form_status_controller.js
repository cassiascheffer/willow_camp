import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["message"]

    connect() {
        if (this.hasMessageTarget && this.messageTarget.classList.contains("success")) {
            // Auto-dismiss success messages after 8 seconds
            setTimeout(() => {
                this.dismiss()
            }, 8000)
        }
    }

    dismiss() {
        if (this.hasMessageTarget) {
            this.messageTarget.classList.add("opacity-0")

            // Remove the element after fade out transition completes
            setTimeout(() => {
                this.messageTarget.remove()
            }, 300)
        }
    }
}
