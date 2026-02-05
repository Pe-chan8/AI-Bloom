import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

eagerLoadControllersFrom("controllers", application)

import GaController from "controllers/ga_controller"
application.register("ga", GaController)

import GaEventController from "controllers/ga_event_controller"
application.register("ga-event", GaEventController)

import HamburgerMenuController from "controllers/hamburger_menu_controller"
application.register("hamburger-menu", HamburgerMenuController)

import HelloController from "controllers/hello_controller"
application.register("hello", HelloController)
