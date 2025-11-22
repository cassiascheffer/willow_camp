// Domain input auto-lowercasing utility
export function registerDomainDowncaseComponent(Alpine) {
  Alpine.data('domainDowncase', () => ({
    downcaseInput(event) {
      const input = event.target
      const start = input.selectionStart
      const end = input.selectionEnd
      input.value = input.value.toLowerCase()
      input.setSelectionRange(start, end)
    }
  }))
}
