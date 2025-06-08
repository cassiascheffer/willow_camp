import { Application } from "@hotwired/stimulus"
import { MarksmithController, ListContinuationController } from '@avo-hq/marksmith'

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

application.register('marksmith', MarksmithController)
application.register('list-continuation', ListContinuationController)

export { application }
