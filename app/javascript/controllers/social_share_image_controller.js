import { Controller } from "@hotwired/stimulus"

// Usage: <div data-controller="social-share-image" data-social-share-image-title-value="Post Title" data-social-share-image-author-value="Author Name" data-social-share-image-favicon-value="🌟">
export default class extends Controller {
  static values = { 
    title: String, 
    author: String, 
    favicon: String,
    blogTitle: String 
  }
  static targets = ["canvas", "downloadLink"]

  connect() {
    this.generateImage()
  }

  async generateImage() {
    const canvas = document.createElement('canvas')
    const ctx = canvas.getContext('2d')
    
    // LinkedIn recommended dimensions: 1200x627
    canvas.width = 1200
    canvas.height = 627
    
    // Extract colors from favicon emoji
    const colors = await this.extractColorsFromFavicon(this.faviconValue || "⛺")
    
    // Create gradient background
    this.createGradientBackground(ctx, canvas.width, canvas.height, colors)
    
    // Add content
    this.addTextContent(ctx, canvas.width, canvas.height)
    this.addFavicon(ctx, canvas.width, canvas.height)
    
    // Convert to blob and create download link
    canvas.toBlob((blob) => {
      const url = URL.createObjectURL(blob)
      if (this.hasDownloadLinkTarget) {
        this.downloadLinkTarget.href = url
        this.downloadLinkTarget.download = `${this.slugify(this.titleValue)}-social-share.png`
      }
      
      // Set as meta tag for social sharing
      this.updateSocialMetaTags(url)
    }, 'image/png', 0.9)
    
    // Add canvas to target if it exists, replacing any existing canvas
    if (this.hasCanvasTarget) {
      // Clear existing canvases
      this.canvasTarget.innerHTML = ''
      this.canvasTarget.appendChild(canvas)
    }
  }

  async extractColorsFromFavicon(emoji) {
    return new Promise((resolve) => {
      // Create a small canvas to render the emoji and extract colors
      const tempCanvas = document.createElement('canvas')
      const tempCtx = tempCanvas.getContext('2d')
      tempCanvas.width = 64
      tempCanvas.height = 64
      
      // Clear canvas with transparent background
      tempCtx.clearRect(0, 0, 64, 64)
      
      // Render emoji
      tempCtx.font = '48px system-ui, Apple Color Emoji, Segoe UI Emoji, Noto Color Emoji, sans-serif'
      tempCtx.textAlign = 'center'
      tempCtx.textBaseline = 'middle'
      tempCtx.fillText(emoji, 32, 32)
      
      // Wait a tick for emoji to render
      setTimeout(() => {
        // Get image data
        const imageData = tempCtx.getImageData(0, 0, 64, 64)
        const data = imageData.data
        
        // Extract dominant colors
        const colorMap = new Map()
        for (let i = 0; i < data.length; i += 4) {
          const r = data[i]
          const g = data[i + 1]
          const b = data[i + 2]
          const a = data[i + 3]
          
          // Skip transparent or near-transparent pixels
          if (a < 100) continue
          
          // Skip near-black and near-white pixels
          const brightness = (r + g + b) / 3
          if (brightness < 20 || brightness > 235) continue
          
          // Group similar colors with larger groupings
          const colorKey = `${Math.floor(r/30)*30},${Math.floor(g/30)*30},${Math.floor(b/30)*30}`
          colorMap.set(colorKey, (colorMap.get(colorKey) || 0) + 1)
        }
        
        // Get most frequent colors
        const sortedColors = Array.from(colorMap.entries())
          .sort((a, b) => b[1] - a[1])
          .slice(0, 4)
          .map(([color]) => {
            const [r, g, b] = color.split(',').map(Number)
            return { r, g, b }
          })
        
        // Convert to muted pastels or use defaults
        const mutedColors = sortedColors.length >= 2
          ? sortedColors.slice(0, 3).map(color => this.createMutedPastel(color))
          : [
              { r: 255, g: 240, b: 245 }, // Light pink
              { r: 240, g: 248, b: 255 }, // Light blue
              { r: 245, g: 255, b: 240 }  // Light green
            ]
        
        resolve(mutedColors)
      }, 50)
    })
  }

  createMutedPastel(color) {
    const { r, g, b } = color
    
    // Simple approach: blend with white and reduce saturation
    // Mix the color with white (70% original, 30% white)
    const whiteBlend = 0.3
    let newR = Math.round(r * (1 - whiteBlend) + 255 * whiteBlend)
    let newG = Math.round(g * (1 - whiteBlend) + 255 * whiteBlend)
    let newB = Math.round(b * (1 - whiteBlend) + 255 * whiteBlend)
    
    // Further desaturate by moving towards gray
    const gray = (newR + newG + newB) / 3
    const desaturationAmount = 0.6 // Keep 40% of original saturation
    
    newR = Math.round(newR * desaturationAmount + gray * (1 - desaturationAmount))
    newG = Math.round(newG * desaturationAmount + gray * (1 - desaturationAmount))
    newB = Math.round(newB * desaturationAmount + gray * (1 - desaturationAmount))
    
    // Ensure we stay in pastel range (light colors)
    newR = Math.max(180, Math.min(255, newR))
    newG = Math.max(180, Math.min(255, newG))
    newB = Math.max(180, Math.min(255, newB))
    
    return { r: newR, g: newG, b: newB }
  }

  createGradientBackground(ctx, width, height, colors) {
    // Create a diagonal gradient for more visual interest
    const gradient = ctx.createLinearGradient(0, 0, width * 0.8, height * 0.8)
    
    if (colors.length >= 2) {
      gradient.addColorStop(0, `rgb(${colors[0].r}, ${colors[0].g}, ${colors[0].b})`)
      if (colors.length >= 3) {
        gradient.addColorStop(0.5, `rgb(${colors[1].r}, ${colors[1].g}, ${colors[1].b})`)
        gradient.addColorStop(1, `rgb(${colors[2].r}, ${colors[2].g}, ${colors[2].b})`)
      } else {
        gradient.addColorStop(1, `rgb(${colors[1].r}, ${colors[1].g}, ${colors[1].b})`)
      }
    } else {
      // Fallback gradient
      gradient.addColorStop(0, 'rgb(255, 240, 245)')
      gradient.addColorStop(1, 'rgb(240, 248, 255)')
    }
    
    ctx.fillStyle = gradient
    ctx.fillRect(0, 0, width, height)
    
    // Add subtle texture overlay with reduced opacity
    ctx.fillStyle = 'rgba(255, 255, 255, 0.05)'
    for (let i = 0; i < 30; i++) {
      const x = Math.random() * width
      const y = Math.random() * height
      const size = Math.random() * 2 + 0.5
      ctx.beginPath()
      ctx.arc(x, y, size, 0, Math.PI * 2)
      ctx.fill()
    }
  }

  addTextContent(ctx, width, height) {
    // Add title
    ctx.fillStyle = '#1a1a1a'
    ctx.textAlign = 'center'
    ctx.textBaseline = 'middle'
    
    // Title font - make it bold and large
    const titleFontSize = this.calculateTitleFontSize(this.titleValue, width - 120)
    ctx.font = `bold ${titleFontSize}px system-ui, -apple-system, sans-serif`
    
    // Draw title with line wrapping
    const titleLines = this.wrapText(ctx, this.titleValue, width - 120)
    const titleY = height * 0.4
    const lineHeight = titleFontSize * 1.2
    
    titleLines.forEach((line, index) => {
      const y = titleY + (index - (titleLines.length - 1) / 2) * lineHeight
      ctx.fillText(line, width / 2, y)
    })
    
    // Add author name
    ctx.font = '32px system-ui, -apple-system, sans-serif'
    ctx.fillStyle = '#4a4a4a'
    const authorY = titleY + (titleLines.length * lineHeight / 2) + 60
    ctx.fillText(this.authorValue || 'Author', width / 2, authorY)
    
    // Add blog title if different from author
    if (this.blogTitleValue && this.blogTitleValue !== this.authorValue) {
      ctx.font = '24px system-ui, -apple-system, sans-serif'
      ctx.fillStyle = '#6a6a6a'
      ctx.fillText(this.blogTitleValue, width / 2, authorY + 40)
    }
  }

  addFavicon(ctx, width, height) {
    // Draw favicon in top-right corner
    ctx.font = '64px system-ui, Apple Color Emoji, Segoe UI Emoji, Noto Color Emoji, sans-serif'
    ctx.textAlign = 'center'
    ctx.textBaseline = 'middle'
    ctx.fillText(this.faviconValue || "⛺", width - 80, 80)
  }

  calculateTitleFontSize(title, maxWidth) {
    const baseSize = 72
    const maxSize = 80
    const minSize = 48
    
    // Estimate size based on character count
    if (title.length < 30) return maxSize
    if (title.length < 50) return Math.max(baseSize, minSize)
    if (title.length < 80) return Math.max(baseSize - 12, minSize)
    return minSize
  }

  wrapText(ctx, text, maxWidth) {
    const words = text.split(' ')
    const lines = []
    let currentLine = words[0]

    for (let i = 1; i < words.length; i++) {
      const word = words[i]
      const width = ctx.measureText(currentLine + ' ' + word).width
      if (width < maxWidth) {
        currentLine += ' ' + word
      } else {
        lines.push(currentLine)
        currentLine = word
      }
    }
    lines.push(currentLine)
    
    // Limit to 3 lines maximum
    return lines.slice(0, 3)
  }

  updateSocialMetaTags(imageUrl) {
    // Remove existing og:image meta tags
    document.querySelectorAll('meta[property="og:image"], meta[name="twitter:image"]').forEach(tag => tag.remove())
    
    // Add new meta tags
    const ogImage = document.createElement('meta')
    ogImage.setAttribute('property', 'og:image')
    ogImage.setAttribute('content', imageUrl)
    document.head.appendChild(ogImage)
    
    const twitterImage = document.createElement('meta')
    twitterImage.setAttribute('name', 'twitter:image')
    twitterImage.setAttribute('content', imageUrl)
    document.head.appendChild(twitterImage)
    
    // Add other social meta tags if they don't exist
    if (!document.querySelector('meta[property="og:title"]')) {
      const ogTitle = document.createElement('meta')
      ogTitle.setAttribute('property', 'og:title')
      ogTitle.setAttribute('content', this.titleValue)
      document.head.appendChild(ogTitle)
    }
    
    if (!document.querySelector('meta[name="twitter:card"]')) {
      const twitterCard = document.createElement('meta')
      twitterCard.setAttribute('name', 'twitter:card')
      twitterCard.setAttribute('content', 'summary_large_image')
      document.head.appendChild(twitterCard)
    }
  }

  slugify(text) {
    return text
      .toLowerCase()
      .replace(/[^\w\s-]/g, '')
      .replace(/[\s_-]+/g, '-')
      .replace(/^-+|-+$/g, '')
  }

  // Action to regenerate image
  regenerate() {
    this.generateImage()
  }
}