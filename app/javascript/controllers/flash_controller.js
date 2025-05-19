import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    // Auto-dismiss flash messages after 5 seconds
    setTimeout(() => {
      this.dismiss();
    }, 5000);
  }

  dismiss() {
    this.element.classList.add("-translate-y-full");

    // Remove the element after transition completes
    setTimeout(() => {
      this.element.remove();
    }, 300);
  }
}
