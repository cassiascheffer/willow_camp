import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="mermaid"
export default class extends Controller {
  connect() {
    this.initializeMermaid()
  }

  async initializeMermaid() {
    const mermaidElements = this.element.querySelectorAll('pre[lang="mermaid"]')
    
    for (const preElement of mermaidElements) {
      await this.processMermaidElement(preElement)
    }
  }

  async processMermaidElement(preElement) {
    try {
      const mermaidModule = await import("mermaid")
      const mermaid = mermaidModule.default || mermaidModule
      
      // Initialize mermaid with configuration (only once)
      if (!this.constructor.mermaidInitialized) {
        mermaid.initialize({
          startOnLoad: false,
          theme: 'default'
        })
        this.constructor.mermaidInitialized = true
      }

      const codeElement = preElement.querySelector('code')
      const diagramText = codeElement ? codeElement.textContent.trim() : preElement.textContent.trim()
      
      if (!diagramText) {
        return
      }
      
      // Generate a unique ID for the diagram
      const diagramId = `mermaid-${crypto.randomUUID()}`
      
      // Create a div to hold the rendered SVG
      const diagramDiv = document.createElement('div')
      diagramDiv.className = 'mermaid-diagram'
      diagramDiv.id = diagramId
      
      // Render the diagram
      const { svg } = await mermaid.render(`${diagramId}-svg`, diagramText)
      diagramDiv.innerHTML = svg
      
      // Replace the pre element with the rendered diagram
      preElement.parentNode.replaceChild(diagramDiv, preElement)
      
    } catch (error) {
      console.error('Error rendering mermaid diagram:', error)
      preElement.classList.add('mermaid-error')
    }
  }
}