import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  confirmDelete() {
    const modal = document.createElement("div")
    modal.innerHTML = `
      <div class="modal modal-open">
        <div class="modal-box">
          <h3 class="font-bold text-lg">Delete Tag</h3>
          <p class="py-4">Are you sure you want to delete this tag? This action cannot be undone.</p>
          <div class="modal-action">
            <button class="btn cancel-btn">Cancel</button>
            <button class="btn btn-error delete-btn">Delete</button>
          </div>
        </div>
      </div>
    `
    
    modal.querySelector('.cancel-btn').addEventListener('click', () => this.cancelDelete())
    modal.querySelector('.delete-btn').addEventListener('click', () => this.executeDelete())
    
    document.body.appendChild(modal)
    this.modal = modal
  }

  cancelDelete() {
    if (this.modal) {
      this.modal.remove()
      this.modal = null
    }
  }

  executeDelete() {
    fetch(this.urlValue, {
      method: 'DELETE',
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
    .then(response => {
      if (response.ok) {
        return response.text()
      }
      throw new Error('Network response was not ok')
    })
    .then(html => {
      if (html.trim()) {
        Turbo.renderStreamMessage(html)
      }
    })
    .catch(error => {
      console.error('Error deleting tag:', error)
    })
    .finally(() => {
      this.cancelDelete()
    })
  }
}