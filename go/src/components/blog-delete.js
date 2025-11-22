// Two-step blog deletion confirmation component
export function registerBlogDeleteComponent(Alpine) {
  Alpine.data('blogDelete', (subdomain) => ({
    showModal: false,
    showFinalModal: false,
    confirmationInput: '',
    errorMessage: '',

    confirmDelete() {
      this.showModal = true
      this.confirmationInput = ''
      this.errorMessage = ''
      this.$nextTick(() => {
        this.$refs.confirmInput?.focus()
      })
    },

    checkMatch() {
      if (this.confirmationInput.length > 0 && this.confirmationInput !== subdomain) {
        this.errorMessage = 'Subdomain does not match. Please try again.'
      } else {
        this.errorMessage = ''
      }
    },

    get isValid() {
      return this.confirmationInput === subdomain
    },

    proceedToFinal() {
      if (this.isValid) {
        this.showModal = false
        this.showFinalModal = true
      }
    },

    cancelModal() {
      this.showModal = false
      this.showFinalModal = false
      this.confirmationInput = ''
      this.errorMessage = ''
    },

    deleteBlog() {
      this.$refs.deleteForm?.submit()
    }
  }))
}
