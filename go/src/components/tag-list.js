// Tag list component for inline editing and deletion
export function registerTagListComponent(Alpine) {
  // Component factory for individual tag items
  Alpine.data('tagItem', (tagId, tagName, tagUrl) => ({
    tagId,
    displayName: tagName,
    editName: tagName,
    editing: false,
    deleting: false,

    init() {
      // Focus input when entering edit mode
      this.$watch('editing', (value) => {
        if (value) {
          this.$nextTick(() => {
            this.$refs.input?.focus()
            this.$refs.input?.select()
          })
        }
      })
    },

    startEdit() {
      this.editName = this.displayName
      this.editing = true
    },

    cancelEdit() {
      this.editName = this.displayName
      this.editing = false
    },

    async saveTag() {
      const newName = this.editName.trim()

      if (!newName) {
        this.$store.toasts.show('Tag name cannot be empty', 'error')
        return
      }

      if (newName === this.displayName) {
        this.editing = false
        return
      }

      try {
        const response = await fetch(tagUrl, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
          body: JSON.stringify({ name: newName })
        })

        const data = await response.json()

        if (response.ok && data.success) {
          this.displayName = data.name
          this.editName = data.name
          this.editing = false
          this.$store.toasts.show('Tag updated successfully', 'success')
        } else {
          this.$store.toasts.show(data.error || 'Failed to update tag', 'error')
        }
      } catch (error) {
        console.error('Tag update error:', error)
        this.$store.toasts.show('Network error. Please try again.', 'error')
      }
    },

    async confirmDelete() {
      if (!confirm(`Are you sure you want to delete the tag "${this.displayName}"? This will remove it from all posts.`)) {
        return
      }

      await this.deleteTag()
    },

    async deleteTag() {
      if (this.deleting) return

      this.deleting = true

      try {
        const response = await fetch(tagUrl, {
          method: 'DELETE',
          headers: {
            'Accept': 'application/json'
          }
        })

        const data = await response.json()

        if (response.ok && data.success) {
          this.$store.toasts.show('Tag deleted successfully', 'success')

          // Remove the tag from the DOM
          const mobileCard = document.getElementById(`tag_${this.tagId}`)
          const desktopRow = document.getElementById(`tag_row_${this.tagId}`)

          if (mobileCard) {
            mobileCard.remove()
          }
          if (desktopRow) {
            desktopRow.remove()
          }

          // Check if there are any tags left, show empty state if not
          const tagsContainer = document.querySelector('[x-data^="tagItem"]')
          if (!tagsContainer) {
            window.location.reload()
          }
        } else {
          this.$store.toasts.show(data.error || 'Failed to delete tag', 'error')
        }
      } catch (error) {
        console.error('Tag deletion error:', error)
        this.$store.toasts.show('Network error. Please try again.', 'error')
      } finally {
        this.deleting = false
      }
    }
  }))
}
