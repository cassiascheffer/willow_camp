// Global toast notification store
export function registerToastsStore(Alpine) {
  Alpine.store('toasts', {
    items: [],
    nextId: 1,

    show(message, type = 'success') {
      const id = this.nextId++
      const toast = {
        id,
        message,
        type,
        visible: true
      }

      this.items.push(toast)

      setTimeout(() => {
        this.hide(id)
      }, 4000)
    },

    hide(id) {
      const toast = this.items.find(t => t.id === id)
      if (toast) {
        toast.visible = false
        setTimeout(() => {
          this.items = this.items.filter(t => t.id !== id)
        }, 300)
      }
    }
  })
}
