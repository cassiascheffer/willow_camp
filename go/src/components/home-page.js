// Home page component with theme and emoji persistence using localStorage
export function registerHomePageComponent(Alpine) {
  Alpine.data('homePage', () => ({
    faviconEmoji: '🏕️',
    faviconCode: '1F3D5',
    theme: 'light',
    showEmojiPicker: false,
    showThemePicker: false,
    emojiData: [],

    // Common emojis for quick selection
    commonEmojis: [
      { emoji: '🏕️', hexcode: '1F3D5', annotation: 'Camping' },
      { emoji: '🌲', hexcode: '1F332', annotation: 'Evergreen tree' },
      { emoji: '🌳', hexcode: '1F333', annotation: 'Deciduous tree' },
      { emoji: '🏔️', hexcode: '1F3D4', annotation: 'Snow-capped mountain' },
      { emoji: '🔥', hexcode: '1F525', annotation: 'Fire' },
      { emoji: '⛺', hexcode: '26FA', annotation: 'Tent' },
      { emoji: '🎒', hexcode: '1F392', annotation: 'Backpack' },
      { emoji: '✍️', hexcode: '270D', annotation: 'Writing hand' },
    ],

    // Available themes
    themes: [
      { id: 'light', name: 'Light' },
      { id: 'dark', name: 'Dark' },
      { id: 'cupcake', name: 'Cupcake' },
      { id: 'bumblebee', name: 'Bumblebee' },
      { id: 'emerald', name: 'Emerald' },
      { id: 'corporate', name: 'Corporate' },
      { id: 'synthwave', name: 'Synthwave' },
      { id: 'retro', name: 'Retro' },
      { id: 'cyberpunk', name: 'Cyberpunk' },
      { id: 'valentine', name: 'Valentine' },
      { id: 'halloween', name: 'Halloween' },
      { id: 'garden', name: 'Garden' },
      { id: 'forest', name: 'Forest' },
      { id: 'aqua', name: 'Aqua' },
      { id: 'lofi', name: 'Lofi' },
      { id: 'pastel', name: 'Pastel' },
      { id: 'fantasy', name: 'Fantasy' },
      { id: 'wireframe', name: 'Wireframe' },
      { id: 'black', name: 'Black' },
      { id: 'luxury', name: 'Luxury' },
      { id: 'dracula', name: 'Dracula' },
      { id: 'cmyk', name: 'CMYK' },
      { id: 'autumn', name: 'Autumn' },
      { id: 'business', name: 'Business' },
      { id: 'acid', name: 'Acid' },
      { id: 'lemonade', name: 'Lemonade' },
      { id: 'night', name: 'Night' },
      { id: 'coffee', name: 'Coffee' },
      { id: 'winter', name: 'Winter' },
    ],

    init() {
      // Load saved preferences from localStorage
      this.loadPreferences()

      // Apply theme to document
      this.applyTheme()

      // Set initial favicon
      this.updateFavicon(this.faviconCode)

      // Load emoji data for search
      this.loadEmojiData()

      // Listen for external changes
      window.addEventListener('favicon-changed', (e) => {
        this.faviconCode = e.detail.code
        this.faviconEmoji = e.detail.emoji
      })

      window.addEventListener('theme-changed', (e) => {
        this.theme = e.detail.theme
        this.applyTheme()
      })

      // Close pickers when clicking outside
      this.$watch('showEmojiPicker', value => {
        if (value) {
          setTimeout(() => {
            document.addEventListener('click', this.handleClickOutside)
          }, 0)
        } else {
          document.removeEventListener('click', this.handleClickOutside)
        }
      })

      this.$watch('showThemePicker', value => {
        if (value) {
          setTimeout(() => {
            document.addEventListener('click', this.handleClickOutside)
          }, 0)
        } else {
          document.removeEventListener('click', this.handleClickOutside)
        }
      })
    },

    loadPreferences() {
      // Load theme
      const savedTheme = localStorage.getItem('theme')
      if (savedTheme) {
        this.theme = savedTheme
      }

      // Load emoji
      const savedEmoji = localStorage.getItem('favicon-emoji')
      const savedCode = localStorage.getItem('favicon-code')
      if (savedEmoji && savedCode) {
        this.faviconEmoji = savedEmoji
        this.faviconCode = savedCode
        
        // Dispatch event to sync with layout
        window.dispatchEvent(new CustomEvent('favicon-changed', { detail: { code: savedCode, emoji: savedEmoji } }))
      }
    },

    applyTheme() {
      document.documentElement.setAttribute('data-theme', this.theme)
    },

    async loadEmojiData() {
      try {
        const response = await fetch('/openmoji-map.json')
        if (!response.ok) throw new Error(`HTTP ${response.status}`)
        this.emojiData = await response.json()
      } catch (error) {
        console.error('Failed to load emoji data:', error)
      }
    },

    selectEmoji(emoji, hexcode) {
      this.faviconEmoji = emoji
      this.faviconCode = hexcode

      // Save to localStorage
      localStorage.setItem('favicon-emoji', emoji)
      localStorage.setItem('favicon-code', hexcode)

      // Update favicon
      this.updateFavicon(hexcode)

      // Dispatch event
      window.dispatchEvent(new CustomEvent('favicon-changed', { detail: { code: hexcode, emoji: emoji } }))

      // Close picker
      this.showEmojiPicker = false
    },

    updateFavicon(hexcode) {
      // Remove existing favicons
      document.querySelectorAll("link[rel*='icon'], link[rel='apple-touch-icon']").forEach(link => link.remove())

      // Create new favicons
      const icoLink = document.createElement('link')
      icoLink.rel = 'icon'
      icoLink.type = 'image/x-icon'
      icoLink.sizes = '32x32'
      icoLink.href = `/openmoji-32x32-ico/${hexcode}.ico`
      document.head.appendChild(icoLink)

      const svgLink = document.createElement('link')
      svgLink.rel = 'icon'
      svgLink.type = 'image/svg+xml'
      svgLink.href = `/openmoji-svg-color/${hexcode}.svg`
      document.head.appendChild(svgLink)

      const appleLink = document.createElement('link')
      appleLink.rel = 'apple-touch-icon'
      appleLink.href = `/openmoji-apple-touch-icon-180x180/${hexcode}.png`
      document.head.appendChild(appleLink)
    },

    selectTheme(themeId) {
      this.theme = themeId

      // Save to localStorage
      localStorage.setItem('theme', themeId)

      // Apply theme
      this.applyTheme()

      // Dispatch event
      window.dispatchEvent(new CustomEvent('theme-changed', { detail: { theme: themeId } }))

      // Close picker
      this.showThemePicker = false
    },

    toggleEmojiPicker() {
      this.showEmojiPicker = !this.showEmojiPicker
      this.showThemePicker = false
    },

    toggleThemePicker() {
      this.showThemePicker = !this.showThemePicker
      this.showEmojiPicker = false
    },

    handleClickOutside(event) {
      // Check if click is outside both pickers
      const emojiPicker = this.$refs.emojiPicker
      const themePicker = this.$refs.themePicker
      const emojiButton = this.$refs.emojiButton
      const themeButton = this.$refs.themeButton

      if (this.showEmojiPicker &&
          emojiPicker &&
          !emojiPicker.contains(event.target) &&
          emojiButton &&
          !emojiButton.contains(event.target)) {
        this.showEmojiPicker = false
      }

      if (this.showThemePicker &&
          themePicker &&
          !themePicker.contains(event.target) &&
          themeButton &&
          !themeButton.contains(event.target)) {
        this.showThemePicker = false
      }
    }
  }))
}
