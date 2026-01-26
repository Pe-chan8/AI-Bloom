import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  post_created() {
    if (typeof gtag === "function") {
      gtag("event", "post_created")
    }
  }
}
