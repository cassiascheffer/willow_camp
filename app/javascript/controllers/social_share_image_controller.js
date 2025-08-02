import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas", "titleInput"]
  static values = {
    postId: String,
    faviconEmoji: String,
    theme: String
  }

  connect() {
    // Generate the image
    this.generate()
    
    // Populate hidden field on form submit
    this.boundHandleSubmit = this.handleFormSubmit.bind(this)
    this.element.addEventListener('submit', this.boundHandleSubmit)
    
    // Regenerate when title changes
    if (this.hasTitleInputTarget) {
      this.boundTitleChange = this.debounce(() => this.generate(), 500)
      this.titleInputTarget.addEventListener('input', this.boundTitleChange)
    }
  }

  disconnect() {
    this.element.removeEventListener('submit', this.boundHandleSubmit)
    if (this.hasTitleInputTarget && this.boundTitleChange) {
      this.titleInputTarget.removeEventListener('input', this.boundTitleChange)
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
    // Check if post is being published by looking for the published field
    const publishedField = this.element.querySelector('input[name="post[published]"]')
    if (!publishedField || publishedField.value !== 'true') {
      return // Let normal submission continue
    }
    
    // Prevent the form submission until we have the image
    event.preventDefault()
    
    // Convert canvas to blob and add to FormData
    const canvas = this.canvasTarget
    canvas.toBlob((blob) => {
      // Find the hidden social_share_image field
      const hiddenField = this.element.querySelector('input[name="post[social_share_image]"]')
      if (hiddenField) {
        // Create a file input to replace the hidden field
        const fileInput = document.createElement('input')
        fileInput.type = 'file'
        fileInput.name = hiddenField.name
        fileInput.style.display = 'none'
        
        // Create a File from the blob and assign it
        const file = new File([blob], `social-share-${Date.now()}.png`, { type: 'image/png' })
        const dataTransfer = new DataTransfer()
        dataTransfer.items.add(file)
        fileInput.files = dataTransfer.files
        
        // Replace the hidden field with the file input
        hiddenField.parentNode.replaceChild(fileInput, hiddenField)
      }
      
      // Now submit the form (remove listener to avoid recursion)
      this.element.removeEventListener('submit', this.boundHandleSubmit)
      this.element.submit()
    }, 'image/png')
  }

  generate() {
    const canvas = this.canvasTarget
    const ctx = canvas.getContext('2d')
    
    // Get the title from the form
    const title = this.hasTitleInputTarget ? this.titleInputTarget.value : 'Untitled Post'
    
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
    
    // Use binary search to find optimal font size
    let minFontSize = 40
    let maxFontSize = 80
    const maxWidth = canvas.width - 120
    const maxLines = 4
    
    let lines = []
    let fontSize = minFontSize
    
    while (minFontSize <= maxFontSize) {
      const testFontSize = Math.floor((minFontSize + maxFontSize) / 2)
      ctx.font = `bold ${testFontSize}px sans-serif`
      const testLines = this.wrapText(ctx, title, maxWidth)
      
      // Check if text fits (both line count and width constraints)
      const fitsLineCount = testLines.length <= maxLines
      const fitsWidth = testLines.every(line => ctx.measureText(line).width <= maxWidth)
      
      if (fitsLineCount && fitsWidth) {
        fontSize = testFontSize
        lines = testLines
        minFontSize = testFontSize + 1 // Try larger font
      } else {
        maxFontSize = testFontSize - 1 // Try smaller font
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
      // Handle very long words that exceed maxWidth by themselves
      if (ctx.measureText(word).width > maxWidth) {
        // Push current line if it exists
        if (currentLine) {
          lines.push(currentLine)
          currentLine = ''
        }
        // Truncate the long word with ellipsis
        let truncated = word
        while (ctx.measureText(truncated + '...').width > maxWidth && truncated.length > 1) {
          truncated = truncated.slice(0, -1)
        }
        lines.push(truncated + (truncated !== word ? '...' : ''))
        continue
      }
      
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