import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { name: String }

  connect() {
    const name = this.nameValue
    console.log("[GA]", name)

    if (typeof gtag === "function") {
      gtag("event", name)
    } else {
      console.log("gtag not ready")
    }

    // 1回送ったら自分を消す（連打防止）
    this.element.remove()
  }
}
