// ABOUTME: This is a Stimulus controller for managing Quill rich text editor instances
// ABOUTME: It handles initialization, content syncing with hidden fields, and image uploads

import { Controller } from "@hotwired/stimulus"
import Quill from "quill"
import { DirectUpload } from "@rails/activestorage"

export default class extends Controller {
  static targets = ["editor", "input"]
  static values = {
    enableFileUploads: { type: Boolean, default: true },
    uploadUrl: { type: String, default: "/rails/active_storage/direct_uploads" }
  }

  connect() {
    this.initializeQuill()
    this.setupEventListeners()
    this.loadInitialContent()
  }

  disconnect() {
    if (this.quill) {
      this.quill = null
    }
  }

  initializeQuill() {
    const toolbarOptions = this.enableFileUploadsValue ?
      [
        ['bold', 'italic', 'underline', 'strike'],
        ['blockquote', 'code-block'],
        [{ 'header': 1 }, { 'header': 2 }],
        [{ 'list': 'ordered'}, { 'list': 'bullet' }],
        [{ 'script': 'sub'}, { 'script': 'super' }],
        [{ 'indent': '-1'}, { 'indent': '+1' }],
        [{ 'size': ['small', false, 'large', 'huge'] }],
        [{ 'header': [1, 2, 3, 4, 5, 6, false] }],
        [{ 'color': [] }, { 'background': [] }],
        [{ 'align': [] }],
        ['link', 'image', 'video'],
        ['clean']
      ] :
      [
        ['bold', 'italic', 'underline', 'strike'],
        ['blockquote', 'code-block'],
        [{ 'header': 1 }, { 'header': 2 }],
        [{ 'list': 'ordered'}, { 'list': 'bullet' }],
        [{ 'script': 'sub'}, { 'script': 'super' }],
        [{ 'indent': '-1'}, { 'indent': '+1' }],
        [{ 'size': ['small', false, 'large', 'huge'] }],
        [{ 'header': [1, 2, 3, 4, 5, 6, false] }],
        [{ 'color': [] }, { 'background': [] }],
        [{ 'align': [] }],
        ['link'],
        ['clean']
      ]

    this.quill = new Quill(this.editorTarget, {
      theme: 'snow',
      modules: {
        toolbar: toolbarOptions
      },
      placeholder: 'Write your content here...'
    })

    if (this.enableFileUploadsValue) {
      this.setupImageHandler()
    }
  }

  setupEventListeners() {
    this.quill.on('text-change', () => {
      this.updateHiddenInput()
    })
  }

  setupImageHandler() {
    const toolbar = this.quill.getModule('toolbar')
    toolbar.addHandler('image', () => {
      this.selectLocalImage()
    })
  }

  selectLocalImage() {
    const input = document.createElement('input')
    input.setAttribute('type', 'file')
    input.setAttribute('accept', 'image/*')
    input.click()

    input.onchange = () => {
      const file = input.files[0]
      if (file && /^image\//.test(file.type)) {
        this.uploadImage(file)
      } else {
        console.warn('You can only upload images.')
      }
    }
  }

  uploadImage(file) {
    const upload = new DirectUpload(file, this.uploadUrlValue)

    const range = this.quill.getSelection(true)
    this.quill.insertEmbed(range.index, 'image', '/loading.gif')
    this.quill.setSelection(range.index + 1)

    upload.create((error, blob) => {
      if (error) {
        console.error('Upload failed:', error)
        this.quill.deleteText(range.index, 1)
      } else {
        const url = `/rails/active_storage/blobs/redirect/${blob.signed_id}/${blob.filename}`
        this.quill.deleteText(range.index, 1)
        this.quill.insertEmbed(range.index, 'image', url)
      }
    })
  }

  loadInitialContent() {
    if (this.hasInputTarget && this.inputTarget.value) {
      const content = this.inputTarget.value

      if (content.startsWith('<') && content.includes('>')) {
        this.quill.root.innerHTML = content
      } else {
        this.quill.setText(content)
      }
    }
  }

  updateHiddenInput() {
    if (this.hasInputTarget) {
      this.inputTarget.value = this.quill.root.innerHTML
    }
  }
}
