// Security and profile management component
export function registerSecurityPageComponent(Alpine) {
  Alpine.data('securityPage', (successMessage, errorMessage) => ({
    submitting: false,
    savingProfile: false,
    savingPassword: false,
    showCurrentPassword: false,
    showNewPassword: false,
    showConfirmPassword: false,
    serverProfileError: '',
    serverPasswordError: '',

    init() {
      const successMessages = {
        'password_updated': 'Password updated successfully',
        'token_created': 'Token created successfully',
        'token_deleted': 'Token deleted successfully',
        'profile_updated': 'Profile updated successfully'
      }

      const errorMessages = {
        'password_required': 'Password is required',
        'password_mismatch': 'Passwords do not match',
        'name_required': 'Token name is required',
        'invalid_date': 'Invalid expiration date',
        'expiration_must_be_future': 'Expiration date must be in the future',
        'email_required': 'Email is required',
        'invalid_password': 'Current password is incorrect'
      }

      if (successMessage && successMessages[successMessage]) {
        this.$store.toasts.show(successMessages[successMessage], 'success')
      }

      if (errorMessage && errorMessages[errorMessage]) {
        this.$store.toasts.show(errorMessages[errorMessage], 'error')
      }
    },

    async submitProfile(event) {
      event.preventDefault()

      const form = event.target

      // Validate form before submission
      if (!form.checkValidity()) {
        // Show validation errors
        form.reportValidity()
        return
      }

      this.savingProfile = true
      this.serverProfileError = ''

      // Get password field references
      const newPasswordField = form.querySelector('input[name="new_password"]')
      const confirmPasswordField = form.querySelector('input[name="confirm_password"]')
      const currentPasswordField = form.querySelector('input[name="current_password"]')

      const formData = new FormData(form)

      try {
        const response = await fetch('/dashboard/security/profile', {
          method: 'POST',
          headers: {
            'Accept': 'application/json'
          },
          body: formData
        })

        const data = await response.json()

        if (data.success) {
          this.$store.toasts.show(data.message, 'success')

          // Clear password fields for security
          if (currentPasswordField) currentPasswordField.value = ''
          if (newPasswordField) newPasswordField.value = ''
          if (confirmPasswordField) confirmPasswordField.value = ''

          // Reset password visibility toggles
          this.showCurrentPassword = false
          this.showNewPassword = false
          this.showConfirmPassword = false
        } else {
          this.serverProfileError = data.message

          // Show error toast for all errors
          this.$store.toasts.show(data.message, 'error')

          // Also set custom validity on the current password field for visual feedback
          if (data.message.toLowerCase().includes('password')) {
            currentPasswordField?.setCustomValidity(data.message)
            currentPasswordField?.reportValidity()
          } else if (data.message.toLowerCase().includes('email')) {
            const emailInput = form.querySelector('input[name="email"]')
            emailInput?.setCustomValidity(data.message)
            emailInput?.reportValidity()
          }
        }

        // Always clear password fields after submission (success or error) for security
        if (currentPasswordField) currentPasswordField.value = ''
        if (newPasswordField) newPasswordField.value = ''
        if (confirmPasswordField) confirmPasswordField.value = ''
      } catch (error) {
        this.serverProfileError = 'Failed to update profile'
        this.$store.toasts.show('Network error. Please try again.', 'error')

        // Always clear password fields for security
        if (currentPasswordField) currentPasswordField.value = ''
        if (newPasswordField) newPasswordField.value = ''
        if (confirmPasswordField) confirmPasswordField.value = ''
      } finally {
        this.savingProfile = false
      }
    },

    async submitPassword(event) {
      event.preventDefault()
      this.savingPassword = true
      this.serverPasswordError = ''

      const formData = new FormData(event.target)

      try {
        const response = await fetch('/dashboard/security/password', {
          method: 'POST',
          headers: {
            'Accept': 'application/json'
          },
          body: formData
        })

        const data = await response.json()

        if (data.success) {
          this.$store.toasts.show(data.message, 'success')
          event.target.reset()
        } else {
          this.serverPasswordError = data.message
        }
      } catch (error) {
        this.serverPasswordError = 'Failed to update password'
        this.$store.toasts.show('Network error. Please try again.', 'error')
      } finally {
        this.savingPassword = false
      }
    }
  }))
}
