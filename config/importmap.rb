# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@avo-hq/marksmith", to: "@avo-hq--marksmith.js" # @0.4.5
pin "mermaid", to: "https://cdn.jsdelivr.net/npm/mermaid@11.6.0/dist/mermaid.esm.min.mjs"
pin "choices.js", to: "https://cdn.jsdelivr.net/npm/choices.js@11.0.2/public/assets/scripts/choices.min.mjs"
