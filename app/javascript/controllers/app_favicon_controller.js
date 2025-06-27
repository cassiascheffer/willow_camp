import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview"]

  connect() {
    // Set initial favicon from cookie or default
    this.setInitialFavicon()
  }

  setInitialFavicon() {
    const savedEmoji = localStorage.getItem('emoji') || "⛺"
    this.setFavicon(savedEmoji)

    // Update preview if target exists
    if (this.hasPreviewTarget) {
      this.previewTarget.textContent = savedEmoji
    }
  }

  selectEmoji(event) {
    const emoji = event.currentTarget.dataset.emojiValue

    // Update preview if target exists
    if (this.hasPreviewTarget) {
      this.previewTarget.textContent = emoji
    }

    // Update favicon
    this.setFavicon(emoji)

    // Store in localStorage for persistence
    localStorage.setItem('emoji', emoji)

    // Close dropdown if it exists
    const dropdown = event.currentTarget.closest('.dropdown')
    if (dropdown) {
      dropdown.querySelector('[tabindex="0"]')?.blur()
    }
  }

  setFavicon(emoji) {
    if (!emoji) return;

    const sizes = [16, 32, 48, 64, 180]
    const fontSizes = {
      16: 14,
      32: 28,
      48: 42,
      64: 56,
      180: 160,
    }

    // Remove old favicons
    document.querySelectorAll('link[rel*="icon"], link[rel="apple-touch-icon"]').forEach(link => link.remove())

    sizes.forEach(size => {
      const cacheKey = `emoji-favicon-${emoji}-${size}`
      let dataUrl = localStorage.getItem(cacheKey)

      if (!dataUrl) {
        const canvas = document.createElement('canvas')
        canvas.width = canvas.height = size
        const ctx = canvas.getContext('2d')
        ctx.textAlign = 'center'
        ctx.textBaseline = 'middle'
        ctx.font = `bold ${fontSizes[size]}px system-ui, Apple Color Emoji, Segoe UI Emoji, Noto Color Emoji, sans-serif`
        ctx.clearRect(0, 0, size, size)
        ctx.fillText(emoji, size / 2, size / 2)
        dataUrl = canvas.toDataURL('image/png')
        try {
          localStorage.setItem(cacheKey, dataUrl)
        } catch (e) {
          // localStorage might be full or disabled; ignore errors
        }
      }

      const link = document.createElement('link')
      link.type = 'image/png'
      link.rel = size === 180 ? 'apple-touch-icon' : 'icon'
      link.sizes = `${size}x${size}`
      link.href = dataUrl
      document.head.appendChild(link)
    })
  }


}
