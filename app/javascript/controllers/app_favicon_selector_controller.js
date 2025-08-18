// ABOUTME: This controller manages favicon selection in the application layout
// ABOUTME: It allows users to choose from OpenMoji assets and updates favicon links accordingly

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview", "logo"]

  connect() {
    // Set initial favicon from localStorage or default
    const savedCode = localStorage.getItem('favicon-code') || '1F3D5'
    const savedEmoji = localStorage.getItem('favicon-emoji') || '🏕'
    this.updateFavicon(savedCode, savedEmoji)
  }

  selectEmoji(event) {
    const button = event.currentTarget
    const emoji = button.dataset.emojiValue
    const code = button.dataset.emojiCode
    
    // Update favicon
    this.updateFavicon(code, emoji)
    
    // Store in localStorage
    localStorage.setItem('favicon-code', code)
    localStorage.setItem('favicon-emoji', emoji)
    
    // Close dropdown
    const dropdown = button.closest('.dropdown')
    if (dropdown) {
      dropdown.querySelector('[tabindex="0"]')?.blur()
    }
  }

  updateFavicon(code, emoji) {
    // Update preview targets
    if (this.hasPreviewTarget) {
      this.previewTarget.innerHTML = `
        <img src="/openmoji-svg-color/${code}.svg" alt="${emoji}" class="w-5 h-5">
      `
    }
    
    // Update logo targets
    this.logoTargets.forEach(logoContainer => {
      const img = logoContainer.querySelector('img')
      if (img) {
        img.src = `/openmoji-svg-color/${code}.svg`
        img.alt = emoji
      }
    })
    
    // Update browser favicon
    this.updateBrowserFavicon(code)
  }

  updateBrowserFavicon(code) {
    // Remove old favicons
    document.querySelectorAll('link[rel*="icon"], link[rel="apple-touch-icon"]').forEach(link => link.remove())
    
    // Add new OpenMoji favicons
    const icoLink = document.createElement('link')
    icoLink.rel = 'icon'
    icoLink.type = 'image/x-icon'
    icoLink.sizes = '32x32'
    icoLink.href = `/openmoji-32x32-ico/${code}.ico`
    document.head.appendChild(icoLink)
    
    const svgLink = document.createElement('link')
    svgLink.rel = 'icon'
    svgLink.type = 'image/svg+xml'
    svgLink.href = `/openmoji-svg-color/${code}.svg`
    document.head.appendChild(svgLink)
    
    const appleLink = document.createElement('link')
    appleLink.rel = 'apple-touch-icon'
    appleLink.href = `/openmoji-apple-touch-icon-180x180/${code}.png`
    document.head.appendChild(appleLink)
  }
}