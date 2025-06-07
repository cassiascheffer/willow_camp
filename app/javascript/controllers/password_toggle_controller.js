import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "eyeIcon", "eyeOffIcon"]

  toggle() {
    const input = this.inputTarget
    const eyeIcon = this.eyeIconTarget
    const eyeOffIcon = this.eyeOffIconTarget

    if (input.type === "password") {
      input.type = "text"
      eyeIcon.classList.add("hidden")
      eyeOffIcon.classList.remove("hidden")
    } else {
      input.type = "password"
      eyeIcon.classList.remove("hidden")
      eyeOffIcon.classList.add("hidden")
    }
  }
}