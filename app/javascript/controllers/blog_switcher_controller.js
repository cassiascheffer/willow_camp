// ABOUTME: Handles blog switcher dropdown and new blog modal interactions
// ABOUTME: Provides methods to show/hide the new blog creation modal

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  showModal() {
    this.modalTarget.showModal()
  }

  hideModal() {
    this.modalTarget.close()
  }
}