import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    postId: String,
    faviconEmoji: String,
    theme: String
  }

  connect() {
    // Get reference to form element
    this.formElement = this.element.querySelector('[data-autosave-target="form"]')
    
    // Generate the image
    this.generate()
    
    // Override form submission for published posts
    if (this.formElement) {
      this.boundHandleSubmit = this.handleFormSubmit.bind(this)
      this.formElement.addEventListener('submit', this.boundHandleSubmit)
    }
    
    // Regenerate when title changes
    const titleInput = document.querySelector('input[name="post[title]"]')
    if (titleInput) {
      titleInput.addEventListener('input', this.debounce(() => this.generate(), 500))
    }
  }

  disconnect() {
    if (this.formElement) {
      this.formElement.removeEventListener('submit', this.boundHandleSubmit)
    }
  }

  debounce(func, wait) {
    let timeout
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout)
        func(...args)
      }
      clearTimeout(timeout)
      timeout = setTimeout(later, wait)
    }
  }

  handleFormSubmit(event) {
    const publishedField = this.formElement.querySelector('input[name="post[published]"]')
    
    // Only intercept if post is published or being published
    if (!publishedField || publishedField.value !== 'true') {
      return // Let normal submission continue
    }
    
    // Prevent default submission
    event.preventDefault()
    
    // Get the canvas and convert to blob
    const canvas = this.canvasTarget
    canvas.toBlob((blob) => {
      // Create FormData from the form
      const formData = new FormData(this.formElement)
      
      // Add the image file
      formData.append('post[social_share_image]', blob, `social-share-${Date.now()}.png`)
      
      // Get form method and action
      const method = this.formElement.method.toUpperCase()
      let url = this.formElement.action
      
      // Handle Rails _method override for PATCH/PUT
      if (formData.has('_method')) {
        formData.delete('_method')
      }
      
      // Submit with fetch
      fetch(url, {
        method: method === 'POST' ? 'PATCH' : method, // Rails uses PATCH for updates
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml'
        },
        body: formData
      })
      .then(response => {
        if (!response.ok) throw new Error('Network response was not ok')
        
        const contentType = response.headers.get('content-type')
        if (contentType && contentType.includes('text/vnd.turbo-stream.html')) {
          return response.text().then(html => {
            Turbo.renderStreamMessage(html)
          })
        } else {
          // Handle redirect
          window.location.href = response.url
        }
      })
      .catch(error => {
        console.error('Error submitting form:', error)
        // Fallback: submit without image
        this.formElement.submit()
      })
    }, 'image/png')
  }

  generate() {
    const canvas = this.canvasTarget
    const ctx = canvas.getContext('2d')
    
    // Get the title from the form
    const titleInput = document.querySelector('input[name="post[title]"]')
    const title = titleInput ? titleInput.value : 'Untitled Post'
    
    // Get theme colors
    const themeColors = this.getThemeColors(this.themeValue)
    
    // Create gradient background
    const gradient = ctx.createLinearGradient(0, 0, canvas.width, canvas.height)
    gradient.addColorStop(0, themeColors.primary)
    gradient.addColorStop(1, themeColors.secondary)
    
    // Fill background
    ctx.fillStyle = gradient
    ctx.fillRect(0, 0, canvas.width, canvas.height)
    
    // Add a subtle overlay for better text readability
    ctx.fillStyle = 'rgba(0, 0, 0, 0.1)'
    ctx.fillRect(0, 0, canvas.width, canvas.height)
    
    // Draw title with dynamic sizing first to calculate positioning
    ctx.fillStyle = '#ffffff'
    ctx.textAlign = 'center'
    ctx.textBaseline = 'middle'
    
    // Start with larger font size and adjust down if needed
    let fontSize = 80
    const minFontSize = 40
    const maxWidth = canvas.width - 120
    const maxLines = 4
    
    let lines = []
    let fitFound = false
    
    while (fontSize >= minFontSize && !fitFound) {
      ctx.font = `bold ${fontSize}px sans-serif`
      lines = this.wrapText(ctx, title, maxWidth)
      
      if (lines.length <= maxLines) {
        // Check if all lines fit within maxWidth
        let allLinesFit = true
        for (let line of lines) {
          if (ctx.measureText(line).width > maxWidth) {
            allLinesFit = false
            break
          }
        }
        if (allLinesFit) {
          fitFound = true
        } else {
          fontSize -= 2
        }
      } else {
        fontSize -= 2
      }
    }
    
    // Calculate positions
    const lineHeight = fontSize * 1.2
    const titleHeight = lines.length * lineHeight
    const emojiSize = 120
    const spacing = 40
    const totalContentHeight = emojiSize + spacing + titleHeight
    const startY = (canvas.height - totalContentHeight) / 2
    
    // Draw emoji at top (use default if none chosen)
    const emoji = this.faviconEmojiValue || '⛺'
    ctx.font = `${emojiSize}px sans-serif`
    ctx.textAlign = 'center'
    ctx.textBaseline = 'middle'
    
    // Add shadow for better visibility
    ctx.shadowColor = 'rgba(0, 0, 0, 0.5)'
    ctx.shadowBlur = 10
    ctx.shadowOffsetX = 0
    ctx.shadowOffsetY = 2
    
    ctx.fillText(emoji, canvas.width / 2, startY + emojiSize / 2)
    
    // Reset shadow for title
    ctx.shadowColor = 'transparent'
    ctx.shadowBlur = 0
    ctx.shadowOffsetX = 0
    ctx.shadowOffsetY = 0
    
    // Draw title lines below emoji
    ctx.font = `bold ${fontSize}px sans-serif`
    const titleStartY = startY + emojiSize + spacing + lineHeight / 2
    
    lines.forEach((line, index) => {
      const y = titleStartY + index * lineHeight
      ctx.fillText(line, canvas.width / 2, y)
    })
  }

  wrapText(ctx, text, maxWidth) {
    const words = text.split(' ')
    const lines = []
    let currentLine = ''
    
    for (let word of words) {
      const testLine = currentLine + (currentLine ? ' ' : '') + word
      const metrics = ctx.measureText(testLine)
      
      if (metrics.width > maxWidth && currentLine) {
        lines.push(currentLine)
        currentLine = word
      } else {
        currentLine = testLine
      }
    }
    if (currentLine) {
      lines.push(currentLine)
    }
    
    return lines
  }

  getThemeColors(theme) {
    // DaisyUI theme colors mapping
    const themes = {
      light: { primary: '#570df8', secondary: '#f000b8' },
      dark: { primary: '#661ae6', secondary: '#d926aa' },
      cupcake: { primary: '#65c3c8', secondary: '#ef9fbc' },
      bumblebee: { primary: '#e0a82e', secondary: '#f9d72f' },
      emerald: { primary: '#66cc8a', secondary: '#377cfb' },
      corporate: { primary: '#4b6bfb', secondary: '#7b92b2' },
      synthwave: { primary: '#e779c1', secondary: '#58c7f3' },
      retro: { primary: '#ef9995', secondary: '#a4cbb4' },
      cyberpunk: { primary: '#ff7598', secondary: '#75d1f0' },
      valentine: { primary: '#e96d7b', secondary: '#a991f7' },
      halloween: { primary: '#f28c18', secondary: '#6d3a9c' },
      garden: { primary: '#5c7f67', secondary: '#ecf4e7' },
      forest: { primary: '#1eb854', secondary: '#1fd65f' },
      aqua: { primary: '#09ecf3', secondary: '#966fb3' },
      lofi: { primary: '#0d0d0d', secondary: '#1a1919' },
      pastel: { primary: '#d1c1d7', secondary: '#f6cbd1' },
      fantasy: { primary: '#6e0b75', secondary: '#007ebd' },
      wireframe: { primary: '#b8b8b8', secondary: '#b8b8b8' },
      black: { primary: '#343232', secondary: '#343232' },
      luxury: { primary: '#dca54c', secondary: '#152747' },
      dracula: { primary: '#ff79c6', secondary: '#bd93f9' },
      cmyk: { primary: '#45aeee', secondary: '#e8488a' },
      autumn: { primary: '#8c0327', secondary: '#d85251' },
      business: { primary: '#1c4e80', secondary: '#7c909a' },
      acid: { primary: '#ff00f4', secondary: '#ff7400' },
      lemonade: { primary: '#519903', secondary: '#e9e92f' },
      night: { primary: '#38bdf8', secondary: '#818cf8' },
      coffee: { primary: '#db924b', secondary: '#6f4e37' },
      winter: { primary: '#047aff', secondary: '#463aa2' },
      dim: { primary: '#9333ea', secondary: '#f97316' },
      nord: { primary: '#5e81ac', secondary: '#81a1c1' },
      sunset: { primary: '#ff865b', secondary: '#fd6f9c' }
    }
    
    return themes[theme] || themes.light
  }
}