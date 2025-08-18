// ABOUTME: This controller provides live preview of OpenMoji favicon assets in the settings form
// ABOUTME: It uses hexcode from data attribute or converts emoji to OpenMoji filenames

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview"]

  connect() {
    this.updatePreview()
  }

  updatePreview() {
    const emoji = this.inputTarget.value || "🏕"
    
    // First try to get hexcode from data attribute (set by emoji-choices controller)
    // Otherwise use a simple fallback conversion
    const hexcode = this.inputTarget.dataset.hexcode || this.emojiToHexcode(emoji)
    
    // Update preview with OpenMoji asset
    if (this.hasPreviewTarget) {
      const img = document.createElement('img')
      img.src = `/openmoji-svg-color/${hexcode}.svg`
      img.alt = emoji
      img.className = 'w-8 h-8'
      
      // Handle error - use default
      img.onerror = () => {
        img.src = '/openmoji-svg-color/1F3D5.svg'
        // Also update browser favicon to default when preview fails
        this.updateBrowserFavicon('1F3D5')
      }
      
      // Clear preview and add new image
      this.previewTarget.innerHTML = ''
      this.previewTarget.appendChild(img)
    }
    
    // Update browser tab favicon
    this.updateBrowserFavicon(hexcode)
  }

  updateBrowserFavicon(hexcode) {
    // Remove existing favicon links
    const existingFavicons = document.querySelectorAll('link[rel*="icon"]')
    existingFavicons.forEach(link => link.remove())
    
    // Add new favicon links with the selected emoji
    const head = document.querySelector('head')
    
    // 32x32 ICO favicon
    const icoLink = document.createElement('link')
    icoLink.rel = 'icon'
    icoLink.href = `/openmoji-32x32-ico/${hexcode}.ico`
    icoLink.sizes = '32x32'
    head.appendChild(icoLink)
    
    // SVG favicon
    const svgLink = document.createElement('link')
    svgLink.rel = 'icon'
    svgLink.href = `/openmoji-svg-color/${hexcode}.svg`
    svgLink.type = 'image/svg+xml'
    head.appendChild(svgLink)
    
    // Apple touch icon
    const appleLink = document.createElement('link')
    appleLink.rel = 'apple-touch-icon'
    appleLink.href = `/openmoji-apple-touch-icon-180x180/${hexcode}.png`
    head.appendChild(appleLink)
  }

  emojiToHexcode(emoji) {
    if (!emoji) return '1F3D5' // Default camping emoji
    
    // Simple conversion - just get base codepoints without variation selectors
    // This is only used as fallback when data-hexcode is not available
    const codepoints = []
    for (const char of emoji) {
      const code = char.codePointAt(0)
      // Skip variation selectors
      if (code === 0xFE0F || code === 0xFE0E) continue
      codepoints.push(code.toString(16).toUpperCase())
    }
    return codepoints.join('-') || '1F3D5'
  }
}