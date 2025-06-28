import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "success"]

  copy() {
    // Copy the text to clipboard
    navigator.clipboard.writeText(this.sourceTarget.textContent).then(() => {
      // Show success message
      this.successTarget.classList.remove("hidden")

      // Hide success message after 2 seconds
      setTimeout(() => {
        this.successTarget.classList.add("hidden")
      }, 2000)
    })
  }
}
