import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static values = { url: String }

  confirmDelete() {
    const modal = document.createElement("div")
    modal.innerHTML = `
      <div class="modal modal-open">
        <div class="modal-box">
          <h3 class="font-bold text-lg">Delete Post</h3>
          <p class="py-4">Are you sure you want to delete this post? This action cannot be undone.</p>
          <div class="modal-action">
            <button class="btn cancel-btn">Cancel</button>
            <button class="btn btn-error delete-btn">Delete</button>
          </div>
        </div>
      </div>
    `

    document.body.appendChild(modal)

    modal.querySelector(".cancel-btn").addEventListener("click", () => {
      modal.remove()
    })

    modal.querySelector(".delete-btn").addEventListener("click", () => {
      this.deletePost()
      modal.remove()
    })

    modal.addEventListener("click", (event) => {
      if (event.target === modal.querySelector(".modal")) {
        modal.remove()
      }
    })
  }

  deletePost() {
    const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

    fetch(this.urlValue, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Accept": "text/html",
        "Turbo-Frame": "_top"
      }
    }).then(response => {
      if (response.redirected) {
        Turbo.visit(response.url)
      }
    })
  }
}