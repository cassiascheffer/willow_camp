// Mermaid diagram rendering component
export function registerMermaidComponent(Alpine) {
  Alpine.data('mermaid', () => ({
    mermaidInitialized: false,

    async init() {
      await this.initializeMermaid()
    },

    async initializeMermaid() {
      // Goldmark renders as <pre><code class="language-mermaid">
      const codeElements = this.$el.querySelectorAll('code.language-mermaid')

      for (const codeElement of codeElements) {
        const preElement = codeElement.parentElement
        if (preElement && preElement.tagName === 'PRE') {
          await this.processMermaidElement(preElement, codeElement)
        }
      }
    },

    async processMermaidElement(preElement, codeElement) {
      try {
        // Dynamically import mermaid only when needed
        const mermaidModule = await import('mermaid')
        const mermaid = mermaidModule.default || mermaidModule

        // Initialize mermaid with configuration (only once globally)
        if (!window.mermaidInitialized) {
          // Detect current theme from DaisyUI
          const currentTheme = document.documentElement.getAttribute('data-theme')
          const darkThemes = ['dark', 'synthwave', 'halloween', 'forest', 'black', 'luxury', 'dracula', 'business', 'night', 'coffee', 'dim', 'sunset']
          const isDark = darkThemes.includes(currentTheme) || (!currentTheme && window.matchMedia('(prefers-color-scheme: dark)').matches)

          mermaid.initialize({
            startOnLoad: false,
            theme: isDark ? 'dark' : 'default'
          })
          window.mermaidInitialized = true
        }

        const diagramText = codeElement.textContent.trim()

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
  }))
}
