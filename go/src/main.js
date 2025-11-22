// Import styles
import './main.css'

// Import and initialize Alpine.js
import Alpine from 'alpinejs'

// Import toast store
import { registerToastsStore } from './stores/toasts.js'

// Import all components
import { registerMermaidComponent } from './components/mermaid.js'
import { registerEmojiPickerComponent } from './components/emoji-picker.js'
import { registerThemeSelectorComponent } from './components/theme-selector.js'
import { registerBlogDeleteComponent } from './components/blog-delete.js'
import { registerDomainDowncaseComponent } from './components/domain-downcase.js'
import { registerSecurityPageComponent } from './components/security-page.js'
import { registerTokenListComponent } from './components/token-list.js'
import { registerAutosaveFormComponent } from './components/autosave-form.js'
import { registerTagChoicesComponent } from './components/tag-choices.js'

// Make Alpine available globally
window.Alpine = Alpine

// Register toast store (must be first, as components depend on it)
registerToastsStore(Alpine)

// Register all components
registerMermaidComponent(Alpine)
registerEmojiPickerComponent(Alpine)
registerThemeSelectorComponent(Alpine)
registerBlogDeleteComponent(Alpine)
registerDomainDowncaseComponent(Alpine)
registerSecurityPageComponent(Alpine)
registerTokenListComponent(Alpine)
registerAutosaveFormComponent(Alpine)
registerTagChoicesComponent(Alpine)

// Start Alpine
Alpine.start()
