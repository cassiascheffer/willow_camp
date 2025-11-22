// Blog theme selector with live preview
export function registerThemeSelectorComponent(Alpine) {
  Alpine.data('themeSelector', (currentTheme) => ({
    selectedTheme: currentTheme || 'light',

    selectTheme(theme) {
      this.selectedTheme = theme

      // Update hidden field
      this.$refs.hiddenField.value = theme

      // Apply theme immediately to document
      document.documentElement.setAttribute('data-theme', theme)

      // Auto-submit form
      this.$el.closest('form').requestSubmit()
    }
  }))
}
