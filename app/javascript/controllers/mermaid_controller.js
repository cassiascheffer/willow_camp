import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="mermaid"
export default class extends Controller {
  connect() {
    this.initializeMermaid()
  }

  async initializeMermaid() {
    // This controller is attached to individual pre elements with lang="mermaid"
    // so this.element is the pre element itself
    if (this.element.getAttribute('lang') !== 'mermaid') {
      return // Safety check - should not happen
    }

    try {
      // Dynamically import mermaid only when needed
      const mermaid = await import("mermaid")
      
      // Initialize mermaid with configuration (only once)
      if (!window.mermaidInitialized) {
        mermaid.default.initialize({
          startOnLoad: false,
          theme: 'default',
          securityLevel: 'loose',
        })
        window.mermaidInitialized = true
      }

      const diagramId = `mermaid-diagram-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
      const codeElement = this.element.querySelector('code')
      const diagramText = codeElement ? codeElement.textContent.trim() : this.element.textContent.trim()
      
      try {
        // Create a div to replace the pre element
        const diagramDiv = document.createElement('div')
        diagramDiv.id = diagramId
        diagramDiv.className = 'mermaid-diagram'
        
        // Render the diagram
        const { svg } = await mermaid.default.render(diagramId, diagramText)
        diagramDiv.innerHTML = svg
        
        // Replace the pre element with the rendered diagram
        this.element.parentNode.replaceChild(diagramDiv, this.element)
      } catch (error) {
        console.error('Error rendering mermaid diagram:', error)
        // Keep the original pre element if rendering fails
        this.element.classList.add('mermaid-error')
        this.element.setAttribute('title', 'Failed to render diagram')
      }
    } catch (error) {
      console.error('Error loading mermaid library:', error)
    }
  }
}