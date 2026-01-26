import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("ga controller connected")
    // Turbo Stream invoke 用
    this.element.post_created = this.post_created.bind(this)
  }

  disconnect() {
    delete this.element.post_created
  }

  post_created() {
    console.log("GA event: post_created")
    if (typeof gtag === "function") {
      gtag("event", "post_created")
    } else {
      console.log("gtag not ready")
    }
  }
}
