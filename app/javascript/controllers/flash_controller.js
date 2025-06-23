import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    // Auto-dismiss flash messages after 5 seconds
    setTimeout(() => {
      this.dismiss();
    }, 5000);
  }

  dismiss() {
    // Fade out the alert
    this.element.style.transition = "opacity 0.3s ease-out";
    this.element.style.opacity = "0";

    // Remove the element after transition completes
    setTimeout(() => {
      this.element.remove();
    }, 300);
  }
}
