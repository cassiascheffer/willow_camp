import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static values = { subdomain: String }
  static targets = ["form"]

  confirmDelete() {
    const modal = document.createElement("div")
    modal.innerHTML = `
      <div class="modal modal-open">
        <div class="modal-box">
          <h3 class="font-bold text-lg text-red-600">Delete Blog</h3>
          <p class="py-4">To delete this blog, please type the subdomain <strong>${this.subdomainValue}</strong> to confirm:</p>
          <input type="text" class="input input-bordered w-full confirmation-input" placeholder="Enter subdomain">
          <p class="text-red-600 text-sm mt-2 hidden error-message">Subdomain does not match. Please try again.</p>
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
      const isMatch = confirmationInput.value === this.subdomainValue
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
      if (confirmationInput.value === this.subdomainValue) {
        this.showFinalConfirmation()
        modal.remove()
      }
    })

    modal.addEventListener("click", (event) => {
      if (event.target === modal.querySelector(".modal")) {
        modal.remove()
      }
    })

    // Focus the input field
    setTimeout(() => confirmationInput.focus(), 100)
  }

  showFinalConfirmation() {
    const modal = document.createElement("div")
    modal.innerHTML = `
      <div class="modal modal-open">
        <div class="modal-box">
          <h3 class="font-bold text-lg text-red-600">Final Confirmation</h3>
          <p class="py-4">Are you absolutely sure? This will permanently delete the blog <strong>${this.subdomainValue}</strong> and all of its posts, pages, and associated data. This action cannot be undone.</p>
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
      this.deleteBlog()
      modal.remove()
    })

    modal.addEventListener("click", (event) => {
      if (event.target === modal.querySelector(".modal")) {
        modal.remove()
      }
    })
  }

  deleteBlog() {
    this.formTarget.submit()
  }
}