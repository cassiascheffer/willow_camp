import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["subdomain", "customDomain"]

  downcaseInput(event) {
    // Downcase the input value as the user types
    const input = event.target
    const start = input.selectionStart
    const end = input.selectionEnd
    
    input.value = input.value.toLowerCase()
    
    // Restore cursor position after downcasing
    input.setSelectionRange(start, end)
  }

  submit(event) {
    // Downcase subdomain field if present (fallback)
    if (this.hasSubdomainTarget) {
      this.subdomainTarget.value = this.subdomainTarget.value.toLowerCase()
    }
    
    // Downcase custom domain field if present (fallback)
    if (this.hasCustomDomainTarget) {
      this.customDomainTarget.value = this.customDomainTarget.value.toLowerCase()
    }
  }
}