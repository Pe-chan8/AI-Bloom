import { application } from "controllers/application"

import PostModalController from "controllers/post_modal_controller"
application.register("post-modal", PostModalController)

import GaController from "controllers/ga_controller"
application.register("ga", GaController)
