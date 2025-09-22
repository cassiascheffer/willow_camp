// ABOUTME: Stimulus controller for initializing TinyMCE editor with pro features
// ABOUTME: Configures TinyMCE from CDN with plugins, toolbar, and content settings

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["editor"]
  static values = { postId: String, blogSubdomain: String }

  connect() {
    this.initEditor()
  }

  disconnect() {
    // Clean up the editor when the controller disconnects
    if (this.editor) {
      tinymce.remove(this.editor)
    }
  }

  initEditor() {
    if (typeof tinymce === 'undefined') {
      console.error('TinyMCE not loaded. Make sure the CDN script is included in your layout.')
      return
    }

    tinymce.init({
      target: this.editorTarget,
      menubar: false,
      toolbar: true,
      plugins: [
        'autolink', 'codesample', 'link', 'lists',
        'media', 'powerpaste', 'table', 'image',
        'quickbars', 'codesample', 'help',
        'markdown', 'fullscreen', 'emoticons', 'wordcount', 'searchreplace', 'save', 'autosavs'
      ],
      toolbar: 'fullscreen save | undo redo | blocks | bold italic underline bullist numlist outdent indent link image media codesample | removeformat | help',
      quickbars_insert_toolbar: false,
      quickbars_selection_toolbar: 'bold italic underline strikethrough | blocks | blockquote quicklink quicktable image codesample',
      contextmenu: 'undo redo | inserttable | cell row column deletetable | codesample image media | help',
      powerpaste_word_import: 'clean',
      powerpaste_html_import: 'clean',
      branding: false,

      // Image upload configuration - attaches to post's content_images
      images_upload_handler: (blobInfo, progress) => {
        return new Promise((resolve, reject) => {
          const formData = new FormData()
          const file = new File([blobInfo.blob()], blobInfo.filename(), { type: blobInfo.blob().type })

          formData.append('file', file)

          // Get CSRF token
          const token = document.querySelector('meta[name="csrf-token"]').content

          // Build the upload URL with the post ID and blog subdomain
          const uploadUrl = `/dashboard/${this.blogSubdomainValue}/posts/${this.postIdValue}/image_uploads`

          fetch(uploadUrl, {
            method: 'POST',
            headers: {
              'X-CSRF-Token': token,
              'Accept': 'application/json'
            },
            body: formData
          })
          .then(response => {
            if (!response.ok) {
              throw new Error(`HTTP error! status: ${response.status}`)
            }
            return response.json()
          })
          .then(data => {
            if (data.location) {
              resolve(data.location)
            } else {
              reject('No image URL returned')
            }
          })
          .catch(error => {
            console.error('Image upload error:', error)
            reject('Image upload failed: ' + error.message)
          })
        })
      },
      automatic_uploads: true,
      setup: (editor) => {
        this.editor = editor

        // Sync content back to the textarea on change
        editor.on('change', () => {
          this.editorTarget.value = editor.getContent()
          // Trigger input event for form validation or autosave
          this.editorTarget.dispatchEvent(new Event('input', { bubbles: true }))
        })
      }
    })
  }
}
