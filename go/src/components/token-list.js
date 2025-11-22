// API token management component
export function registerTokenListComponent(Alpine) {
  Alpine.data('tokenList', () => ({
    tokens: [],
    loading: false,
    submitting: false,

    async init() {
      await this.fetchTokens()
    },

    async fetchTokens() {
      this.loading = true
      try {
        const response = await fetch('/dashboard/tokens', {
          headers: {
            'Accept': 'application/json'
          }
        })

        if (response.ok) {
          const data = await response.json()
          // Ensure tokens is always an array, even if server returns null
          this.tokens = data || []
        } else {
          console.error('Failed to fetch tokens:', response.status)
          this.$store.toasts.show('Failed to load tokens', 'error')
          this.tokens = []
        }
      } catch (error) {
        console.error('Error fetching tokens:', error)
        this.$store.toasts.show('Network error loading tokens', 'error')
        this.tokens = []
      } finally {
        this.loading = false
      }
    },

    async createToken(event) {
      event.preventDefault()

      if (this.submitting) return

      const form = event.target

      // Validate form before submission
      if (!form.checkValidity()) {
        // Show validation errors
        form.reportValidity()
        return
      }

      this.submitting = true

      const formData = new FormData(form)

      try {
        const response = await fetch(form.action, {
          method: 'POST',
          headers: {
            'Accept': 'application/json'
          },
          body: formData
        })

        const data = await response.json()

        if (response.ok && data.success) {
          this.$store.toasts.show(data.message || 'Token created successfully', 'success')
          form.reset()

          // Add the new token to the list
          if (data.token) {
            this.tokens.unshift(data.token)
          }
        } else {
          this.$store.toasts.show(data.message || 'Failed to create token', 'error')
        }
      } catch (error) {
        console.error('Token creation error:', error)
        this.$store.toasts.show('Network error. Please try again.', 'error')
      } finally {
        this.submitting = false
      }
    },

    async deleteToken(tokenId) {
      if (!confirm('Are you sure you want to revoke this token?')) {
        return
      }

      try {
        const response = await fetch(`/dashboard/tokens/${tokenId}/delete`, {
          method: 'POST',
          headers: {
            'Accept': 'application/json'
          }
        })

        const data = await response.json()

        if (response.ok && data.success) {
          this.$store.toasts.show(data.message || 'Token deleted successfully', 'success')

          // Remove token from the list
          this.tokens = this.tokens.filter(t => t.id !== tokenId)
        } else {
          this.$store.toasts.show(data.message || 'Failed to delete token', 'error')
        }
      } catch (error) {
        console.error('Token deletion error:', error)
        this.$store.toasts.show('Network error. Please try again.', 'error')
      }
    },

    formatDate(dateString) {
      if (!dateString) return ''

      const date = new Date(dateString)
      return date.toLocaleDateString('en-US', {
        month: 'short',
        day: '2-digit',
        year: 'numeric'
      })
    }
  }))
}
