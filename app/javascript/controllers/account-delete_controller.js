import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { username: String, canDelete: Boolean }
  static targets = ["form"]

  confirmDelete() {
    if (!this.canDeleteValue) {
      alert("You must delete all your blogs before you can delete your account.")
      return
    }

    const modal = document.createElement("div")
    modal.innerHTML = `
      <div class="modal modal-open">
        <div class="modal-box">
          <h3 class="font-bold text-lg text-red-600">Delete Account</h3>
          <p class="py-4">To delete your account, please type your username <strong>${this.usernameValue}</strong> to confirm:</p>
          <input type="text" class="input input-bordered w-full confirmation-input" placeholder="Enter username">
          <p class="text-red-600 text-sm mt-2 hidden error-message">Username does not match. Please try again.</p>
          <div class="modal-action">
            <button class="btn cancel-btn">Cancel</button>
            <button class="btn btn-error delete-btn" disabled>Delete</button>
          </div>
        </div>
      </div>
    `

    document.body.appendChild(modal)

    const confirmationInput = modal.querySelector(".confirmation-input")
    const deleteBtn = modal.querySelector(".delete-btn")
    const errorMessage = modal.querySelector(".error-message")

    confirmationInput.addEventListener("input", () => {
      const isMatch = confirmationInput.value === this.usernameValue
      deleteBtn.disabled = !isMatch
      
      if (confirmationInput.value.length > 0 && !isMatch) {
        errorMessage.classList.remove("hidden")
      } else {
        errorMessage.classList.add("hidden")
      }
    })

    modal.querySelector(".cancel-btn").addEventListener("click", () => {
      modal.remove()
    })

    modal.querySelector(".delete-btn").addEventListener("click", () => {
      if (confirmationInput.value === this.usernameValue) {
        this.showFinalConfirmation()
        modal.remove()
      }
    })

    modal.addEventListener("click", (event) => {
      if (event.target === modal.querySelector(".modal")) {
        modal.remove()
      }
    })

    setTimeout(() => confirmationInput.focus(), 100)
  }

  showFinalConfirmation() {
    const modal = document.createElement("div")
    modal.innerHTML = `
      <div class="modal modal-open">
        <div class="modal-box">
          <h3 class="font-bold text-lg text-red-600">Final Confirmation</h3>
          <p class="py-4">Are you absolutely sure? This will permanently delete your account <strong>${this.usernameValue}</strong> and all associated data. This action cannot be undone.</p>
          <div class="modal-action">
            <button class="btn cancel-btn">Cancel</button>
            <button class="btn btn-error final-delete-btn">Yes, Delete Forever</button>
          </div>
        </div>
      </div>
    `

    document.body.appendChild(modal)

    modal.querySelector(".cancel-btn").addEventListener("click", () => {
      modal.remove()
    })

    modal.querySelector(".final-delete-btn").addEventListener("click", () => {
      this.deleteAccount()
      modal.remove()
    })

    modal.addEventListener("click", (event) => {
      if (event.target === modal.querySelector(".modal")) {
        modal.remove()
      }
    })
  }

  deleteAccount() {
    this.formTarget.submit()
  }
}