import { application } from "./application"

import PostModalController from "./post_modal_controller"
application.register("post-modal", PostModalController)

import HamburgerMenuController from "./hamburger_menu_controller"
application.register("hamburger-menu", HamburgerMenuController)
