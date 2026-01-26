import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Turbo Stream invoke が呼べるように DOM要素にメソッドを生やす
    this.element.post_created = this.post_created.bind(this)
  }

  disconnect() {
    delete this.element.post_created
  }

  post_created() {
    if (typeof gtag === "function") {
      gtag("event", "post_created")
    }
  }
}
