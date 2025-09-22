# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@rails/activestorage", to: "activestorage.esm.js"
pin "mermaid", to: "https://cdn.jsdelivr.net/npm/mermaid@11.11.0/dist/mermaid.esm.min.mjs"
pin "choices.js", to: "https://cdn.jsdelivr.net/npm/choices.js@11.1.0/public/assets/scripts/choices.min.mjs"
