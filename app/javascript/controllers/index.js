import { application } from "controllers/application"

import HamburgerMenuController from "controllers/hamburger_menu_controller"
application.register("hamburger-menu", HamburgerMenuController)

import HelpTipController from "controllers/help_tip_controller"
application.register("help-tip", HelpTipController)

import MetaCollapseController from "controllers/meta_collapse_controller"
application.register("meta-collapse", MetaCollapseController)

import GaController from "controllers/ga_controller"
application.register("ga", GaController)

import GaEventController from "controllers/ga_event_controller"
application.register("ga-event", GaEventController)
