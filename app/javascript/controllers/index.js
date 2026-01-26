import { application } from "./application.js"

import PostModalController from "./post_modal_controller.js"
application.register("post-modal", PostModalController)

import GaController from "./ga_controller.js"
application.register("ga", GaController)
